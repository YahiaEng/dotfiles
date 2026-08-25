// modules/settings/common/PageBase.qml — the page contract every group page
// implements (RESEARCH.md pattern #5, Caelestia's PageBase). Title band
// plus a flickable body, matching PanelDialog.qml's own header+Flickable
// shape rather than inventing a second frame idiom in this shell.
import QtQuick
import ".."
import "../../"
import "../../dashboard"

Item {
    id: root

    required property string title
    required property SettingsState sState
    default property alias contentChild: bodyColumn.data

    // Exposed so Pages.qml can scroll a keyboard-focused row into view
    // (fourth live-pass follow-on, Rule 2 — discovered while verifying
    // the row-hover fix via grim+PIL: a row past the fold gets its
    // `rowFocused` ring set correctly, but nothing ever moved the
    // Flickable to show it, so the very fix being verified was
    // invisible for any row that didn't already fit on screen).
    property alias flickable: bodyFlick

    // ── Content width cap (quick task 260825-v3u) ────────────────────────
    // Caelestia's `NexusTokens.maxContentWidth`, 800
    // (plugin/src/Caelestia/Config/tokens.hpp:220), which its own PageBase
    // exposes as `cappedWidth` for exactly this reason. Load-bearing now
    // that the window is screen-sized rather than 960 wide: an uncapped
    // `SettingsSection` binds `width: parent.width`, so on this host every
    // toggle row would stretch its label to the far left and its switch to
    // the far right with ~1.5x the old gap of dead space between them —
    // a row you have to track across to read.
    //
    // The cap is on the CONTENT column only, not on the Flickable, so the
    // whole pane still catches wheel and drag rather than only its left
    // 800px. The title stays full-width and left-aligned with the content,
    // matching Caelestia's own header, which uses `Layout.fillWidth: true`
    // beside capped rows.
    readonly property int cappedWidth: Math.min(800, width - Design.panelPadding * 2)

    Column {
        id: headerColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Design.panelPadding

        Text {
            text: root.title
            font.pixelSize: Design.fontHeading
            font.weight: Design.weightEmphasis
            color: Colours.onSurface
        }
    }

    Flickable {
        id: bodyFlick
        anchors.top: headerColumn.bottom
        anchors.topMargin: Design.spacingLg
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Design.panelPadding
        clip: true
        contentHeight: bodyColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: bodyColumn
            // `Math.max(0, ...)` rather than the bare cap: `root.width` is 0
            // for the frame between incubation and anchoring (Pages.qml
            // incubates each page and assigns `anchors.fill` afterwards), and
            // a negative width is a QML warning plus a zero-size layout that
            // some children latch onto.
            width: Math.max(0, Math.min(root.cappedWidth, bodyFlick.width))
            spacing: Design.spacingLg
        }
    }
}
