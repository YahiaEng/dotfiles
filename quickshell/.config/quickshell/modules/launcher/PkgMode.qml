// modules/launcher/PkgMode.qml — the `+` route (quick task 260828-75k,
// direction D3).
//
// ── WHY `+` AND NOT `pkg ` ────────────────────────────────────────────
// The study drew this as `pkg nvid`, but every route in this launcher is
// a SINGLE character (`=` calc, `/` files, `:` clipboard, `.` symbols,
// `;` providerlist, `@` websearch) — a convention inherited from walker's
// own `[[providers.prefixes]]` table and preserved verbatim through the
// QML migration. `_routeQuery()` keys the table on `charAt(0)`, so a
// word prefix would need a second routing shape maintained beside the
// first, and a four-character route would be the odd one out in the
// providerlist that exists to teach these. `+` reads as "add a package"
// and is unclaimed. Stated here because it IS a deviation from what was
// approved in the study.
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

    Text {
        anchors.centerIn: parent
        visible: root.results.length === 0
        text: root.pattern.length === 0 ? "Type a package name" : ("Nothing matches “" + root.pattern + "”")
        font.pixelSize: Design.settingsFontSub
        color: Colours.outline
        textFormat: Text.PlainText
    }
}
