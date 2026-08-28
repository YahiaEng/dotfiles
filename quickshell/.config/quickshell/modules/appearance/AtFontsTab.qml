// modules/appearance/AtFontsTab.qml — the Atelier's Fonts tab (quick task
// 260828-ah9, Task 2; rebuilt operator round 1, defects 2b/2d).
//
// M2 — MEASURED, not a style choice: 13 of 39 installed font entries are
// metrically identical twins. 39 names = 13 families x {`Nerd Font`,
// `Nerd Font Mono`, `Nerd Font Propo`}; `Nerd Font` and `Nerd Font Mono`
// are identical on every probed advance width (fontTools hmtx/head,
// checked across FiraCode/JetBrainsMono/Hack/Iosevka/CaskaydiaCove/
// MesloLGS) — only `Propo` differs, and only on icon glyphs.
// `AppearanceBackend.fontFamilies` already resolved which raw name backs
// each behaviour; this file only groups and renders what it hands back.
//
// ── OPERATOR ROUND 1 ROOT CAUSE (2b + 2d — one defect, not two) ────────
// The measurement was always correct: the backend already emits 13
// families x 2 behaviours, never a third "Nerd Font alone" row. The BUG
// was in this file's old flat ListView, which rendered all 26 of those
// rows as if each were its own family — so "FiraCode" appeared twice in
// a row (once for Mono, once for Propo) and read as a duplicate. The fix
// is presentation, not measurement: GROUP by family in the left rail (13
// rows), and push the behaviour choice into a detail pane on the right,
// per the design study's `.fontsplit` + `.specimen` blocks.
import QtQuick
import ".."
import "../dashboard"

Item {
    id: root

    // One row per FAMILY (13, per M2), never per raw name. Each entry
    // carries every behaviour-row `AppearanceBackend.fontFamilies` has
    // for that family, so the detail pane can offer Mono/Propo without
    // re-deriving anything the backend already resolved.
    readonly property var _families: {
        var raw = AppearanceBackend.fontFamilies;
        var byFamily = {};
        var order = [];
        for (var i = 0; i < raw.length; ++i) {
            var r = raw[i];
            if (!byFamily[r.family]) {
                byFamily[r.family] = {
                    family: r.family,
                    variants: [],
                    active: false
                };
                order.push(r.family);
            }
            byFamily[r.family].variants.push(r);
            if (r.active)
                byFamily[r.family].active = true;
        }
        var out = [];
        for (var j = 0; j < order.length; ++j)
            out.push(byFamily[order[j]]);
        return out;
    }

    // Which family the rail has selected. Empty means "no explicit pick
    // yet" — `_selectedEntry` below then defaults to whichever family is
    // ACTIVE, falling back to the first family, so the detail pane is
    // never blank on first open.
    property string selectedFamily: ""

    readonly property var _selectedEntry: {
        if (root._families.length === 0)
            return null;
        if (root.selectedFamily.length > 0) {
            for (var i = 0; i < root._families.length; ++i)
                if (root._families[i].family === root.selectedFamily)
                    return root._families[i];
        }
        for (var j = 0; j < root._families.length; ++j)
            if (root._families[j].active)
                return root._families[j];
        return root._families[0];
    }

    Text {
        anchors.centerIn: parent
        visible: root._families.length === 0
        text: AppearanceBackend.rawFontsProbed ? "No nerd fonts found" : "Loading fonts…"
        color: Colours.outline
        font.pixelSize: Design.settingsFontSub
    }

    Row {
        anchors.fill: parent
        visible: root._families.length > 0
        spacing: 0

        // ── Left rail — 13 families, never 26 rows (defect 2d's fix). ──
        ListView {
            id: rail
            width: 220
            height: parent.height
            clip: true
            model: root._families

            delegate: Rectangle {
                id: railRow
                required property var modelData

                readonly property bool selected: railRow.modelData.family === root._selectedEntry.family

                width: rail.width
                height: 44
                radius: 10
                color: railRow.selected ? Colours.surfaceVariant : "transparent"

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.colourDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.colourEasing
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Design.spacingSm
                    spacing: Design.spacingXs

                    Text {
                        width: parent.width - countLabel.implicitWidth - Design.spacingXs
                        text: railRow.modelData.family
                        color: railRow.modelData.active ? Colours.primary : Colours.onSurface
                        font.pixelSize: Design.settingsFontSub
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Text {
                        id: countLabel
                        text: railRow.modelData.active ? "active" : (railRow.modelData.variants.length + "")
                        color: Colours.onSurfaceVariant
                        font.pixelSize: Design.fontLabel
                        textFormat: Text.PlainText
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.selectedFamily = railRow.modelData.family
                }
            }
        }

        // ── Right pane — the specimen (defect 2b's fix: variants live
        //    HERE, not as separate rail rows). ────────────────────────
        Column {
            id: specimen
            width: parent.width - rail.width
            height: parent.height
            padding: Design.spacingMd
            spacing: Design.spacingMd

            readonly property var entry: root._selectedEntry
            readonly property var variants: specimen.entry ? specimen.entry.variants : []
            // Which behaviour the specimen is currently rendering.
            // Defaults to whichever variant is ACTIVE, else Mono, else
            // whatever is first — never blank while variants exist.
            property string previewBehaviour: ""

            readonly property var _activeVariant: {
                var vs = specimen.variants;
                if (vs.length === 0)
                    return null;
                for (var i = 0; i < vs.length; ++i)
                    if (vs[i].behaviour === specimen.previewBehaviour)
                        return vs[i];
                for (var j = 0; j < vs.length; ++j)
                    if (vs[j].active)
                        return vs[j];
                for (var k = 0; k < vs.length; ++k)
                    if (vs[k].behaviour === "mono")
                        return vs[k];
                return vs[0];
            }

            // A Nerd-collapsed family (M2) always has at least one
            // behaviour-typed variant. A passthrough (non-Nerd) family's
            // single row carries `behaviour === ""`.
            readonly property bool _nerdCollapsed: {
                var vs = specimen.variants;
                for (var i = 0; i < vs.length; ++i)
                    if (vs[i].behaviour.length > 0)
                        return true;
                return false;
            }

            onEntryChanged: specimen.previewBehaviour = ""

            Text {
                width: specimen.width - specimen.padding * 2
                text: specimen.entry ? (specimen.entry.family + " — " + (specimen._activeVariant ? specimen._activeVariant.rawName : "")) : ""
                color: Colours.onSurfaceVariant
                font.pixelSize: Design.fontLabel
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            // Pangram, rendered in the currently previewed variant's font.
            Text {
                width: specimen.width - specimen.padding * 2
                text: "Sphinx of black quartz, judge my vow"
                font.family: specimen._activeVariant ? specimen._activeVariant.rawName : ""
                font.pixelSize: 22
                color: Colours.onSurface
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
            }

            // A short code sample.
            Text {
                width: specimen.width - specimen.padding * 2
                text: "fn main() { let x = 42; println!(\"{}\", x); }"
                font.family: specimen._activeVariant ? specimen._activeVariant.rawName : ""
                font.pixelSize: 13
                color: Colours.onSurfaceVariant
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
            }

            // Nerd Font glyph run — home / folder / git-branch / terminal
            // / gear, the same five code points font-switcher.sh's own
            // retired preview verified present in the installed set's
            // cmap. Written as explicit `\u` escapes, never a literal
            // pasted glyph — a private-use codepoint is invisible in a
            // diff and in this file's own source.
            Text {
                text: "\uf015 \uf07b \ue725 \uf489 \uf013"
                font.family: specimen._activeVariant ? specimen._activeVariant.rawName : ""
                font.pixelSize: 20
                color: Colours.tertiary
                textFormat: Text.PlainText
            }

            // ── Variant bar — Mono/Propo chips (click applies, matching
            //    the icon-tile click-to-apply precedent), plus a struck
            //    GHOST chip for the collapsed "Nerd Font alone" cut
            //    (M2) — never offered as a real choice, only noted. ────
            Flow {
                width: specimen.width - specimen.padding * 2
                spacing: Design.spacingSm

                Repeater {
                    model: specimen.variants

                    delegate: Rectangle {
                        id: vchip
                        required property var modelData

                        readonly property bool on: vchip.modelData.active

                        radius: 99
                        color: vchip.on ? Qt.alpha(Colours.primary, 0.16) : "transparent"
                        border.width: 1
                        border.color: vchip.on ? Colours.primary : Qt.alpha(Colours.outline, 0.5)
                        width: vchipLabel.implicitWidth + Design.spacingMd
                        height: vchipLabel.implicitHeight + Design.spacingSm

                        Text {
                            id: vchipLabel
                            anchors.centerIn: parent
                            text: vchip.modelData.behaviour === "mono" ? "Mono" : (vchip.modelData.behaviour === "propo" ? "Propo" : "Apply")
                            color: vchip.on ? Colours.primary : Colours.onSurfaceVariant
                            font.pixelSize: Design.fontLabel
                            textFormat: Text.PlainText
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                specimen.previewBehaviour = vchip.modelData.behaviour;
                                AppearanceBackend.applyFont(vchip.modelData.rawName);
                            }
                        }
                    }
                }

                // The M2 ghost — "Nerd Font" alone is metrically
                // identical to the Mono cut above and is never offered
                // as its own choice.
                Rectangle {
                    visible: specimen._nerdCollapsed
                    radius: 99
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.alpha(Colours.outline, 0.35)
                    opacity: 0.45
                    width: ghostLabel.implicitWidth + Design.spacingMd
                    height: ghostLabel.implicitHeight + Design.spacingSm

                    Text {
                        id: ghostLabel
                        anchors.centerIn: parent
                        text: "Nerd Font"
                        font.strikeout: true
                        color: Colours.onSurfaceVariant
                        font.pixelSize: Design.fontLabel
                        textFormat: Text.PlainText
                    }
                }
            }
        }
    }
}
