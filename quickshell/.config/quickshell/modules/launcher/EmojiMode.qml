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
import "../dashboard"
import "fuzzy.js" as Fuzzy

Item {
    id: root

    width: parent ? parent.width : 0
    height: Math.min(320, root._allEntries.length > 0 ? 4 * 64 : 80)

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
    onCurrentIndexChanged: root._ensureVisible()

    // Keeps the row holding `currentIndex` inside the Flickable's visible
    // window — the same "scroll to reveal the selected row" behaviour a
    // virtualizing view provides natively, reimplemented by hand because
    // this file deliberately does NOT use one (see the Flickable/Grid
    // header note below).
    function _ensureVisible() {
        const row = Math.floor(root.currentIndex / 4);
        const rowY = row * 64;
        if (rowY < grid.contentY)
            grid.contentY = rowY;
        else if (rowY + 64 > grid.contentY + grid.height)
            grid.contentY = rowY + 64 - grid.height;
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
            // simply fails this call silently; the copy below still runs
            // independently, which is the graceful degradation this
            // file's header documents.
            //
            // Bug 1 fix (quick task 260822-sht): all three commands below
            // are fire-and-forget (no stdin, and this file never reads
            // their stdout/exit code back), so `Quickshell.execDetached`
            // — same fix as PickerMode.qml's own header — spawns them
            // independent of this Item's lifetime. `dismissCallback()` a
            // few lines down tears down this whole surface (and every
            // child `Process` on it) via shell.qml's LazyLoader the
            // instant it fires; a plain `Process` here raced that
            // teardown exactly like PickerMode.qml's `theme-apply` did.
            Quickshell.execDetached(["wtype", validatedGlyph]);
            Quickshell.execDetached(["wl-copy", validatedGlyph]);
            Quickshell.execDetached(["notify-send", "-a", "Emoji", "Copied", validatedGlyph, "-t", "2000"]);
        }

        if (typeof root.dismissCallback === "function")
            root.dismissCallback();
    }

    // Flickable + Grid + Repeater, deliberately NOT a `GridView` (quick
    // task 260822-sht, Task 9 verification fix): a virtualizing
    // `GridView` here reproduced a consistent, deterministic clip on
    // row 0 and column 0's delegates — confirmed on this host across
    // four independent structural fixes (deferred construction behind a
    // `Loader`, explicit `contentX`/`contentY`/`currentIndex` resets, and
    // an added outer margin, which shifted the clipped region WITH the
    // grid rather than resolving it, ruling out an external clip mask or
    // edge-proximity cause) — grim-screenshot verified live each time,
    // never fixed. At 160 lightweight Rectangle+Text delegates (no image
    // decode, unlike WallpaperPage.qml's own GridView-for-90-thumbnails
    // case that virtualization genuinely earns its keep for), eager
    // rendering via a plain `Grid` costs nothing worth virtualizing away,
    // so this sidesteps the bug entirely rather than chasing its root
    // cause further. `_ensureVisible()` above hand-rolls the "scroll to
    // reveal the selected row" behaviour a virtualizing view would
    // otherwise provide for free.
    Flickable {
        id: grid
        anchors.fill: parent
        clip: true
        interactive: false
        contentWidth: width
        contentHeight: gridPositioner.height

        // Item 2 fix (quick task 260822-sht, operator-reported: "I cannot
        // use my mouse to scroll inside the emoji picker"). ROOT CAUSE:
        // `interactive: false` above disables flicking AND wheel scrolling
        // outright — it is kept `false` here deliberately (this whole
        // package is keyboard-driven; drag-flicking would fight
        // `_ensureVisible()`'s own currentIndex-driven scroll), so the fix
        // is a dedicated `WheelHandler` that moves `contentY` directly
        // rather than re-enabling `interactive`. `acceptedDevices:
        // PointerDevice.AllDevices` is REQUIRED, not decorative — this
        // shell's own measured, load-bearing finding (OsdSliderRow.qml,
        // MediaConnectivityCapsule.qml's `audioWheelHandler`/
        // `brightnessWheelHandler`): Qt's Wayland backend reports the seat
        // pointer as `PointerDevice.TouchPad` for EVERY pointing device on
        // this host, including a real mouse, so a `WheelHandler` left at
        // its default `acceptedDevices: Mouse` fires zero events. Notch
        // quantization (accumulate `angleDelta.y` to 120-unit steps) is
        // the same pattern those two handlers use, so a touchpad's
        // fractional events scroll proportionally instead of firing a
        // full row-step per micro-event. Scrolling is independent of
        // keyboard `currentIndex` — matches every other scrollable surface
        // in this shell (NotifCentre.qml's `historyList`,
        // PageBase.qml's `bodyFlick`), where the wheel pans the view
        // without moving a selection — and never touches the per-tile
        // `MouseArea` below, so click-to-pick is unaffected.
        WheelHandler {
            id: gridWheelHandler
            target: null
            acceptedDevices: PointerDevice.AllDevices

            property real pendingAngle: 0

            onWheel: event => {
                gridWheelHandler.pendingAngle += event.angleDelta.y;
                const notchUnits = 120;
                const rowHeight = 64;
                const maxY = Math.max(0, gridPositioner.height - grid.height);
                while (Math.abs(gridWheelHandler.pendingAngle) >= notchUnits) {
                    const direction = gridWheelHandler.pendingAngle > 0 ? 1 : -1;
                    gridWheelHandler.pendingAngle -= direction * notchUnits;
                    grid.contentY = Math.max(0, Math.min(maxY, grid.contentY - direction * rowHeight));
                }
            }
        }

        Grid {
            id: gridPositioner
            width: parent.width
            columns: 4

            Repeater {
                model: root._rows

                delegate: Rectangle {
                    id: emojiDelegate
                    required property var modelData
                    required property int index

                    width: Math.floor(gridPositioner.width / 4) - Design.spacingXs
                    height: 64 - Design.spacingXs
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
                            width: emojiDelegate.width - 8
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
    }
}
