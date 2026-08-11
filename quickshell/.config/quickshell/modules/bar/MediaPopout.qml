// MediaPopout.qml — the media section's popout body (Phase 18 Plan 14,
// QBAR-09). The last of the five bodies this plan ships. Follows
// WifiPopout.qml's shape as the closest in-plan precedent.
//
// ── Readiness verdict this body relies on ────────────────────────────────
// No pending phase exists — confirmed directly against MediaBackend.qml
// (18-08's repoint), not repeated from this plan's own claim: `widgetState`
// there is a two-branch expression, `!hasPlayer ? "empty" : "populated"`,
// with no third branch anywhere in the file. The native Mpris singleton is
// populated at first paint, so the not-yet-resolved value survives only in
// the vocabulary and is never actually reachable. This body binds only the
// two branches that can occur.
//
// ── The album art trust boundary ─────────────────────────────────────────
// This file reads MediaBackend.artPath — the already-resolved path
// property only. It never reads the raw trackArtUrl and never invokes the
// resolver: that boundary stays exactly where MediaBackend.qml and
// MediaTab.qml already put it, so this body adds no new trust boundary. It
// is a second renderer of a value the shipped Media tab already renders,
// with one addition neither the Media tab nor DashboardTab.qml's compact
// widget carries: an explicit decode bound sized to the drawn thumbnail
// (T-18-14-04) — this body is reachable from a 400ms hover rather than
// only a deliberate tab open, so the image decoder is reachable more often
// and by a shorter gesture, and bounding the decode to the pixels actually
// drawn is the mitigation that shrinks that surface without removing the
// art.
//
// Track metadata (title, artist) is written by whichever application
// created the stream, so it gets the same treatment 18-10 gave tray
// strings and 18-13 gave audio device labels: an explicitly declared plain
// format, right elision. The title is deliberately the backend's FULL
// display title, not the bar's capped form — UI-SPEC names this popout as
// the place the uncapped title lives.
import QtQuick
import "../"
import "../dashboard"

SectionPopout {
    id: root

    property var mediaBackend: null

    sectionId: "media"
    popoutTitle: "Media"
    popoutGlyph: "music_note"

    // populated when a real player exists, the nothing-here value with
    // copy naming that nothing is playing otherwise. The register's
    // not-yet-resolved value is deliberately NOT bound here — see this
    // file's own header note on why it is structurally unreachable.
    bodyState: (root.mediaBackend && root.mediaBackend.hasPlayer) ? "populated" : "empty"
    emptyStateGlyph: "music_off"
    emptyStateText: "Nothing is playing"

    wayfindingLabel: "Open Media tab"
    // dashboardWindow.tabIndexMedia (modules/Dashboard.qml) is 1 —
    // confirmed by reading that file's own declared tab constants rather
    // than counting the tab list by hand.
    onWayfindingActivated: PopoutController.requestDashboard(1)

    readonly property int _artSize: Design.iconSizeMd * 2

    Row {
        id: mediaRow
        visible: root.bodyState === "populated"
        width: parent.width
        spacing: Design.spacingSm

        // ── Album art — a small square thumbnail, bounded decode. ───────
        Item {
            id: artSlot
            width: root._artSize
            height: root._artSize

            Rectangle {
                anchors.fill: parent
                radius: Design.spacingXs
                color: Colours.surfaceVariant
            }

            Image {
                id: artImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize.width: root._artSize
                sourceSize.height: root._artSize
                source: (root.mediaBackend && root.mediaBackend.artPath) ? ("file://" + root.mediaBackend.artPath) : ""
                visible: artImage.status === Image.Ready
            }

            Text {
                id: artPlaceholderGlyph
                anchors.centerIn: parent
                visible: artImage.status !== Image.Ready
                textFormat: Text.PlainText
                text: "music_note"
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                color: Colours.onSurfaceVariant
            }
        }

        Column {
            id: mediaTextColumn
            width: parent.width - artSlot.width - Design.spacingSm
            anchors.verticalCenter: artSlot.verticalCenter
            spacing: Design.spacingXs

            // The full uncapped title — never Design.mediaTitleMaxChars,
            // the bar's own cap. This popout is deliberately the one place
            // the full title lives.
            Text {
                id: titleText
                width: parent.width
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: root.mediaBackend ? root.mediaBackend.displayTitle : ""
                font.pixelSize: Design.fontBody
                font.weight: Design.weightEmphasis
                color: Colours.onSurface
            }
            Text {
                id: artistText
                width: parent.width
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: root.mediaBackend ? root.mediaBackend.displayArtist : ""
                font.pixelSize: Design.fontLabel
                color: Colours.onSurfaceVariant
            }
        }
    }

    // ── A non-interactive progress line — no pointer handler of any kind.
    //    Rendered only when the backend reports a real length; its value
    //    updates from the refresh MediaBackend.qml already runs, so this
    //    file declares no timing object of its own — a position display is
    //    the single most natural place in this whole plan for someone to
    //    add one, and this is the comment recording that it does not. ────
    Item {
        id: progressLine
        visible: root.bodyState === "populated" && root.mediaBackend && root.mediaBackend.lengthSeconds > 0
        width: parent.width
        height: 3

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Colours.surfaceVariant
        }
        Rectangle {
            width: (root.mediaBackend && root.mediaBackend.lengthSeconds > 0)
                ? parent.width * Math.max(0, Math.min(1, root.mediaBackend.positionSeconds / root.mediaBackend.lengthSeconds))
                : 0
            height: parent.height
            radius: height / 2
            color: Colours.primary
        }
    }

    // ── Transport row — exactly three controls, no seek, no volume, no
    //    player selector. Seek in particular is deliberately absent: a
    //    drag gesture on a surface that can be dismissed by the pointer
    //    leaving it is a mis-click waiting to happen, and seeking is one
    //    of the things the foot link reaches. ───────────────────────────
    Row {
        id: transportRow
        visible: root.bodyState === "populated"
        spacing: Design.spacingMd

        Item {
            id: prevButton
            width: Design.iconSizeMd + Design.spacingSm * 2
            height: width

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Colours.surfaceVariant
            }
            Text {
                id: prevGlyph
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: "skip_previous"
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd - 4
                color: Colours.onSurfaceVariant
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (root.mediaBackend)
                        root.mediaBackend.previousTrack();
                }
            }
        }

        Item {
            id: playPauseButton
            width: Design.iconSizeMd + Design.spacingMd * 2
            height: width

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Colours.primary
            }
            Text {
                id: playPauseGlyph
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: (root.mediaBackend && root.mediaBackend.playing) ? "pause" : "play_arrow"
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                color: Colours.onPrimary
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (root.mediaBackend)
                        root.mediaBackend.playPause();
                }
            }
        }

        Item {
            id: nextButton
            width: Design.iconSizeMd + Design.spacingSm * 2
            height: width

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Colours.surfaceVariant
            }
            Text {
                id: nextGlyph
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: "skip_next"
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd - 4
                color: Colours.onSurfaceVariant
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (root.mediaBackend)
                        root.mediaBackend.nextTrack();
                }
            }
        }
    }

    // ── The multi-player case — one line, not a list. Switching players
    //    is a detail-surface action. ─────────────────────────────────────
    Text {
        id: multiPlayerText
        visible: root.bodyState === "populated" && root.mediaBackend && root.mediaBackend.players.length > 1
        width: parent.width
        textFormat: Text.PlainText
        text: root.mediaBackend ? (root.mediaBackend.players.length + " players — switch in the dashboard") : ""
        font.pixelSize: Design.fontLabel
        color: Colours.onSurfaceVariant
    }
}
