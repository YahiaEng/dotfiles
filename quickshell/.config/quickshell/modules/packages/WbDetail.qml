// modules/packages/WbDetail.qml — the right column: the focused package's
// full record, and the removal queue with its cascade preview.
//
// ── THE PREVIEW IS THE POINT ──────────────────────────────────────────
// This is the one capability that made D4 worth its extra ~600 lines over
// a settings page, and the one thing Octopi does that genuinely earns its
// place. `pacman -Rs --print` resolves the FULL cascade unprivileged —
// measured on this host, ticking the 6 orphans produces 11 actual
// removals, because netpbm, docbook-xml, poppler-qt6, ebook-tools and
// convertlit come along behind them. Ticking six things and removing
// eleven is exactly the surprise a preview exists to prevent.
//
// When pacman refuses (a dependency would break) it says which package
// needs what, and that message is shown as pacman wrote it rather than
// replaced with a generic failure.
//
// ── NOTHING HERE RUNS A TRANSACTION ───────────────────────────────────
// "Review in <terminal>" hands a literal argv array to the backend, which
// opens the terminal on the real `paru` command. pacman then prints the
// transaction and asks. This pane never escalates and never runs pacman
// itself — see PackagesBackend's header for why that is the design.
import QtQuick
import ".."
import "../dashboard"

Item {
    id: root

    required property var bench

    implicitWidth: 320
    width: 320

    readonly property var backend: root.bench.backend
    readonly property var row: root.bench.focusRow
    readonly property var pkg: root.row ? root.backend.packageByName(root.row.name) : null

    readonly property bool hasQueue: root.bench.selected.length > 0

    // ── Per-package update, two-step arm ────────────────────────────
    // ABSORBED VERBATIM IN BEHAVIOUR from the retired UpdatesPage.qml,
    // including its reasoning, because the reasoning is the feature:
    //
    //   * The command carries NO `-y`. `paru -Sy <pkg>` is the documented
    //     Arch partial-upgrade footgun — it refreshes the sync database
    //     and then installs ONE package against a system that has not
    //     been upgraded, dragging in newer dependencies. Omitting it
    //     bounds the transaction to the database already on disk.
    //     `checkupdates` syncs into a TEMPORARY db and never touches
    //     /var/lib/pacman/sync, so the honest worst case is that paru
    //     reports nothing to do — a no-op, in the safe direction.
    //   * `--needed` turns a stale-database hit into an explicit skip
    //     rather than a same-version reinstall.
    //   * TWO clicks, and the risk is stated at the point of action
    //     between them. A 6 s timer disarms on its own.
    property string _armedUpdate: ""

    Timer {
        id: disarmTimer
        interval: 6000
        running: false
        repeat: false
        onTriggered: root._armedUpdate = ""
    }

    function _updateClicked(name) {
        if (root._armedUpdate === name) {
            root._armedUpdate = "";
            disarmTimer.stop();
            root.backend.install([name]);
            return;
        }
        root._armedUpdate = name;
        disarmTimer.restart();
    }

    function _joinOr(list, fallback) {
        if (!list || list.length === 0)
            return fallback;
        return list.join(", ");
    }

    // Declared ABOVE the visual tree: `model: root.pkg ? root._fields() : []`
    // below is a binding created at CONSTRUCTION time, and a member declared
    // after it reads as "not a function" there — this tree's own recorded
    // declare-before-construction-time-use rule.
    function _extraNames() {
        var sel = root.bench.selected;
        var out = [];
        var c = root.backend.previewCascade;
        for (var i = 0; i < c.length; ++i)
            if (sel.indexOf(c[i].name) < 0)
                out.push(c[i].name);
        if (out.length > 6)
            return out.slice(0, 6).join(", ") + " and " + (out.length - 6) + " more";
        return out.join(", ");
    }

    function _fields() {
        var p = root.pkg;
        if (!p)
            return [];
        var out = [];
        out.push({
            k: "Version",
            v: p.version,
            tone: "normal"
        });
        var u = root.row ? root.row.update : null;
        if (u)
            out.push({
                k: "Update",
                v: u.from + " → " + u.to,
                tone: "accent"
            });
        out.push({
            k: "Source",
            v: root.backend.sourceOf(p.name),
            tone: "normal"
        });
        out.push({
            k: "Size",
            v: p.sizeText + (root.backend.totalSizeMiB > 0 ? "  ·  " + (p.sizeMiB / root.backend.totalSizeMiB * 100).toFixed(1) + "% of " + root.backend.formatSize(root.backend.totalSizeMiB) : ""),
            tone: "normal"
        });
        out.push({
            k: "Reason",
            v: p.explicit ? "Explicitly installed" : "Installed as a dependency",
            tone: "normal"
        });
        // "Nothing depends on this" is NOT the same claim as "orphan".
        // pacman's own definition (`-Qdt`) is dependency-installed AND
        // unrequired; an EXPLICITLY installed package with no dependents
        // is simply a leaf you asked for. The first version called `linux`
        // an orphan, which it is not — caught on a render.
        var orphan = root.backend.isOrphan(p.name);
        out.push({
            k: "Required by",
            v: root._joinOr(p.requiredBy, orphan ? "Nothing — an orphan, safe to remove" : "Nothing — but you asked for it explicitly"),
            tone: orphan ? "accent" : "normal"
        });
        out.push({
            k: "Depends on",
            v: root._joinOr(p.dependsOn, "Nothing"),
            tone: "normal"
        });
        out.push({
            k: "Installed",
            v: p.installDate.length > 0 ? p.installDate : "—",
            tone: "normal"
        });
        if (p.url.length > 0)
            out.push({
                k: "Upstream",
                v: p.url,
                tone: "normal"
            });
        out.push({
            k: "Licenses",
            v: p.licenses.length > 0 ? p.licenses : "—",
            tone: "normal"
        });
        return out;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.surface, 0.35)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Qt.alpha(Colours.outline, 0.4)
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: Design.spacingMd
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: flick.width
            spacing: Design.spacingMd

            // ── Queue ───────────────────────────────────────────────
            Column {
                width: parent.width
                spacing: Design.spacingSm
                visible: root.hasQueue

                Text {
                    text: "QUEUE · " + root.bench.selected.length + " selected"
                    font.pixelSize: 10
                    font.letterSpacing: 0.8
                    color: Colours.outline
                }

                Rectangle {
                    width: parent.width
                    implicitHeight: queueCol.implicitHeight + Design.spacingSm * 2
                    radius: 14
                    color: Qt.alpha(Colours.onSurface, 0.07)

                    Column {
                        id: queueCol
                        x: Design.spacingSm
                        y: Design.spacingSm
                        width: parent.width - Design.spacingSm * 2
                        spacing: 3

                        Repeater {
                            model: root.bench.selected

                            delegate: Text {
                                required property var modelData
                                width: queueCol.width
                                text: modelData
                                font.pixelSize: Design.fontLabel
                                color: Colours.onSurface
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            width: queueCol.width
                            height: 1
                            color: Qt.alpha(Colours.outline, 0.4)
                        }

                        // ── The cascade ─────────────────────────────
                        Text {
                            width: queueCol.width
                            visible: root.backend.previewRunning
                            text: "Resolving what this removes…"
                            font.pixelSize: Design.fontLabel
                            color: Colours.outline
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: queueCol.width
                            visible: root.backend.previewError.length > 0
                            text: root.backend.previewError
                            font.pixelSize: Design.fontLabel
                            color: Colours.error
                            wrapMode: Text.WordWrap
                        }

                        Item {
                            width: queueCol.width
                            implicitHeight: cascadeCol.implicitHeight
                            visible: root.backend.previewError.length === 0 && !root.backend.previewRunning && root.backend.previewCascade.length > 0

                            Column {
                                id: cascadeCol
                                width: parent.width
                                spacing: 3

                                Row {
                                    width: parent.width

                                    Text {
                                        text: "Removes"
                                        font.pixelSize: Design.fontLabel
                                        color: Colours.onSurfaceVariant
                                    }

                                    Item {
                                        width: cascadeCol.width - 120
                                        height: 1
                                    }

                                    Text {
                                        text: root.backend.previewCascade.length + " packages"
                                        font.pixelSize: Design.fontLabel
                                        color: root.backend.previewCascade.length > root.bench.selected.length ? Colours.primary : Colours.onSurfaceVariant
                                    }
                                }

                                // Named plainly when the cascade is wider
                                // than the selection — the whole reason
                                // this preview exists.
                                Text {
                                    width: cascadeCol.width
                                    visible: root.backend.previewCascade.length > root.bench.selected.length
                                    text: "Also removes " + (root.backend.previewCascade.length - root.bench.selected.length) + " package(s) nothing else needs: " + root._extraNames()
                                    font.pixelSize: Design.fontLabel
                                    color: Colours.primary
                                    wrapMode: Text.WordWrap
                                }

                                Row {
                                    width: parent.width

                                    Text {
                                        text: "Reclaims"
                                        font.pixelSize: Design.fontLabel
                                        color: Colours.onSurfaceVariant
                                    }

                                    Item {
                                        width: cascadeCol.width - 120
                                        height: 1
                                    }

                                    Text {
                                        text: root.backend.formatSize(root.backend.previewReclaimMiB)
                                        font.pixelSize: Design.fontLabel
                                        color: Colours.onSurface
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Design.spacingSm

                    WbButton {
                        label: root.backend.dbLocked ? "pacman is busy" : "Review in " + Prefs.getValue("apps.terminal")
                        tone: "primary"
                        enabled: !root.backend.dbLocked && root.backend.previewError.length === 0
                        onActivated: {
                            if (root.backend.remove(root.bench.selected))
                                root.bench.clearSelection();
                        }
                    }

                    WbButton {
                        label: "Clear"
                        tone: "ghost"
                        onActivated: root.bench.clearSelection()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.alpha(Colours.outline, 0.4)
                }
            }

            // ── Focused package ─────────────────────────────────────
            Text {
                width: parent.width
                visible: !root.row
                text: "Select a package to see what it is, what needs it, and what removing it would take with it."
                font.pixelSize: Design.settingsFontSub
                color: Colours.outline
                wrapMode: Text.WordWrap
            }

            Column {
                width: parent.width
                spacing: Design.spacingSm
                visible: !!root.row

                Text {
                    width: parent.width
                    text: root.row ? root.row.name : ""
                    font.pixelSize: Design.settingsFontRow
                    font.weight: Design.weightEmphasis
                    color: Colours.onSurface
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: !!root.pkg && root.pkg.description.length > 0
                    text: root.pkg ? root.pkg.description : ""
                    font.pixelSize: Design.fontLabel
                    color: Colours.onSurfaceVariant
                    wrapMode: Text.WordWrap
                }

                // Not installed — the repo-search case. Says so, and
                // offers the one action that applies.
                Column {
                    width: parent.width
                    spacing: Design.spacingSm
                    visible: !!root.row && !root.row.installed

                    Text {
                        width: parent.width
                        text: "Not installed · available in " + (root.row ? root.row.source : "")
                        font.pixelSize: Design.fontLabel
                        color: Colours.tertiary
                    }

                    WbButton {
                        label: root.backend.dbLocked ? "pacman is busy" : "Install in " + Prefs.getValue("apps.terminal")
                        tone: "primary"
                        enabled: !root.backend.dbLocked
                        onActivated: root.backend.install([root.row.name])
                    }
                }

                // Installed — the full record.
                Column {
                    width: parent.width
                    spacing: 4
                    visible: !!root.pkg

                    Repeater {
                        model: root.pkg ? root._fields() : []

                        delegate: Row {
                            id: fieldRow
                            required property var modelData
                            width: parent ? parent.width : 0
                            spacing: Design.spacingSm

                            Text {
                                width: 92
                                text: fieldRow.modelData.k
                                font.pixelSize: Design.fontLabel
                                color: Colours.outline
                            }

                            Text {
                                width: fieldRow.width - 92 - Design.spacingSm
                                text: fieldRow.modelData.v
                                font.pixelSize: Design.fontLabel
                                color: fieldRow.modelData.tone === "accent" ? Colours.primary : Colours.onSurface
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                // Update this package — only when there IS one, so the
                // control cannot be read as "reinstall".
                Column {
                    width: parent.width
                    spacing: Design.spacingSm
                    visible: !!root.row && !!root.row.update

                    WbButton {
                        label: {
                            if (root.backend.dbLocked)
                                return "pacman is busy";
                            if (root._armedUpdate === (root.row ? root.row.name : ""))
                                return "Click again to run";
                            return "Update this package";
                        }
                        tone: root._armedUpdate === (root.row ? root.row.name : "") ? "danger" : "primary"
                        enabled: !root.backend.dbLocked
                        onActivated: root._updateClicked(root.row.name)
                    }

                    Text {
                        width: parent.width
                        visible: root._armedUpdate === (root.row ? root.row.name : "")
                        text: "Updates only this package — a partial upgrade, which can break Arch. Use Update all when in doubt."
                        font.pixelSize: Design.fontLabel
                        color: Colours.error
                        wrapMode: Text.WordWrap
                    }
                }

                Row {
                    width: parent.width
                    spacing: Design.spacingSm
                    visible: !!root.pkg

                    WbButton {
                        label: "Mark explicit"
                        tone: "ghost"
                        enabled: !root.backend.dbLocked && !!root.pkg && !root.pkg.explicit
                        onActivated: root.backend.markExplicit([root.row.name])
                    }

                    WbButton {
                        label: root.bench.isSelected(root.row ? root.row.name : "") ? "Unqueue" : "Queue removal"
                        tone: "danger"
                        enabled: !!root.row
                        onActivated: root.bench.toggleSelected(root.row.name)
                    }
                }
            }
        }
    }

}
