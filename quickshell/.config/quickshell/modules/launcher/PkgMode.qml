// modules/launcher/PkgMode.qml — the `pkg` route (quick task 260828-75k,
// direction D3).
//
// ── THE ROUTE IS THE WORD `pkg` ──────────────────────────────────────
// It shipped as `+` first, on the reasoning that every other route here is
// a single character (`=` calc, `/` files, `:` clipboard, `.` symbols, `;`
// providerlist, `@` websearch) inherited from walker's own prefixes table.
// The operator rejected it — "+" reads as punctuation, not as a command —
// so LauncherState grew a second, word-shaped route table beside the
// character one. The single-character vocabulary is untouched.
//
// "pkg" matches only at the very start and only alone or followed by a
// space, so `pkgfile` stays an ordinary app search rather than becoming a
// package query for "file".
//
// ── WHAT IT SEARCHES ──────────────────────────────────────────────────
// Installed packages first (ranked: exact, then prefix, then substring),
// then repo packages that are NOT installed, so "have I got this?" is
// answered before "can I get it?". Both come from PackagesBackend, which
// is already in memory — this mode spawns nothing and polls nothing.
//
// ── WHAT ACTIVATING DOES ──────────────────────────────────────────────
// Opens the workbench on that package. It deliberately does NOT install
// or remove: a launcher row is a lookup, and a transaction started from
// a fuzzy match on a half-typed name is exactly the accident this shell
// should not make easy. The workbench is one keystroke further and shows
// what the package is, what needs it and what removing it would take.
import QtQuick
import ".."
import "../dashboard"
import "../packages"

Item {
    id: root

    width: parent ? parent.width : 0
    height: Math.min(320, Math.max(root.count, 1) * 34)

    readonly property string pattern: LauncherState.queryArg.trim().toLowerCase()

    // Duck-typed interface Launcher.qml's keyboard-nav glue reads.
    property int currentIndex: 0
    readonly property int count: root.results.length

    readonly property int _cap: 40

    // Declared above the ListView that reads it at construction time.
    readonly property var results: {
        var out = [];
        if (root.pattern.length === 0)
            return out;

        var q = root.pattern;
        var installed = PackagesBackend.packages;
        var scored = [];
        var i;

        for (i = 0; i < installed.length; ++i) {
            var p = installed[i];
            var n = p.name.toLowerCase();
            var at = n.indexOf(q);
            if (at < 0)
                continue;
            // Exact 0, prefix 1, substring 2 — then shorter names first,
            // so "gcc" outranks "gcc-libs" for the query "gcc".
            var rank = (n === q) ? 0 : (at === 0 ? 1 : 2);
            scored.push({
                rank: rank,
                len: n.length,
                row: {
                    name: p.name,
                    version: p.version,
                    sizeText: p.sizeText,
                    source: PackagesBackend.sourceOf(p.name),
                    installed: true,
                    update: PackagesBackend.updateFor(p.name)
                }
            });
        }

        scored.sort(function (a, b) {
            if (a.rank !== b.rank)
                return a.rank - b.rank;
            if (a.len !== b.len)
                return a.len - b.len;
            return a.row.name < b.row.name ? -1 : 1;
        });

        for (i = 0; i < scored.length && out.length < root._cap; ++i)
            out.push(scored[i].row);

        // Then the repos, excluding anything already listed above.
        var cat = PackagesBackend.catalogue;
        for (i = 0; i < cat.length && out.length < root._cap; ++i) {
            var c = cat[i];
            if (c.installed)
                continue;
            if (c.name.toLowerCase().indexOf(q) < 0)
                continue;
            out.push({
                name: c.name,
                version: c.version,
                sizeText: "",
                source: c.repo,
                installed: false,
                update: null
            });
        }
        return out;
    }

    onPatternChanged: root.currentIndex = 0

    function activate() {
        var entry = root.results[root.currentIndex];
        if (!entry)
            return;
        PackagesBackend.openWorkbench(entry.name, "");
    }

    ListView {
        id: pkgList
        anchors.fill: parent
        clip: true
        interactive: false
        model: root.results
        currentIndex: root.currentIndex

        delegate: Rectangle {
            id: pkgDelegate
            required property var modelData
            required property int index

            width: pkgList.width
            height: 34
            radius: 8
            color: root.currentIndex === pkgDelegate.index ? Colours.surfaceVariant : "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.currentIndex = pkgDelegate.index;
                    root.activate();
                }
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: Design.spacingMd
                anchors.rightMargin: Design.spacingMd
                spacing: Design.spacingSm

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, pkgList.width * 0.42)
                    text: pkgDelegate.modelData.name
                    font.pixelSize: Design.settingsFontSub
                    color: pkgDelegate.modelData.installed ? Colours.onSurface : Colours.onSurfaceVariant
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !!pkgDelegate.modelData.update
                    text: "update"
                    font.pixelSize: 10
                    color: Colours.primary
                    textFormat: Text.PlainText
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: pkgDelegate.modelData.version
                    font.pixelSize: Design.fontLabel
                    color: Colours.outline
                    textFormat: Text.PlainText
                }

                Item {
                    height: 1
                    width: Math.max(0, parent.width - x - trailing.implicitWidth - Design.spacingSm)
                }

                Row {
                    id: trailing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Design.spacingSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: pkgDelegate.modelData.sizeText
                        font.pixelSize: Design.fontLabel
                        color: Colours.onSurfaceVariant
                        textFormat: Text.PlainText
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        // "not installed" rather than the repo name alone:
                        // the repo name on its own reads as a fact about
                        // where it came from, not as the state that
                        // matters here.
                        text: pkgDelegate.modelData.installed ? pkgDelegate.modelData.source : ("not installed · " + pkgDelegate.modelData.source)
                        font.pixelSize: Design.fontLabel
                        color: pkgDelegate.modelData.installed ? (pkgDelegate.modelData.source === "AUR" ? Colours.tertiary : Colours.outline) : Colours.tertiary
                        textFormat: Text.PlainText
                    }
                }
            }
        }
    }
    // Scroll indicator (quick task 260828-pol). Sibling of the view,
    // never a child: a Flickable/ListView appends Item children to its
    // scrolled contentItem, so a bar declared inside scrolls away.
    ThemedScrollBar {
        flickable: pkgList
    }

    Text {
        anchors.centerIn: parent
        visible: root.results.length === 0
        text: root.pattern.length === 0 ? "Type a package name" : ("Nothing matches “" + root.pattern + "”")
        font.pixelSize: Design.settingsFontSub
        color: Colours.outline
        textFormat: Text.PlainText
    }
}
