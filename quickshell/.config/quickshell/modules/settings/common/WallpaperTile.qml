// modules/settings/common/WallpaperTile.qml — one wallpaper thumbnail.
//
// Ported from caelestia-dots/shell @ 1d0e5a5
// (modules/nexus/pages/wallandstyle/WallItem.qml), vendored at
// .planning/notes/caelestia-filepicker/WallItem.qml. Their shape kept:
// square clipping rect, image cross-fading in over a loading indicator,
// centred elided caption beneath, whole tile clickable.
//
// ANIMATED TILES ARE OURS, NOT THEIRS (operator decision, 2026-08-26).
// Caelestia's tile is a plain `Image`; video has no reference to copy. A
// live wallpaper here plays in place:
//   - gif/webp -> AnimatedImage (cheap, decodes on the GUI thread)
//   - mp4/mkv/webm/mov -> QtMultimedia MediaPlayer + VideoOutput
//     (verified present: /usr/lib/qt6/qml/QtMultimedia exposes
//     QQuickMediaPlayer and QQuickVideoOutput)
//
// THE COST, AND THE GUARD. Several decoding videos in a scrolling grid is a
// real risk on this NVIDIA host, so playback is gated on `playing`, which
// the owning page sets only for tiles inside the viewport. GridView already
// destroys off-screen delegates; this gate covers the band that is
// instantiated but not yet visible. A poster frame is shown until the first
// video frame arrives, reusing the frames the wallpaper pipeline already
// extracts to ~/.local/state/theme/wallpaper-frames/ — so a live tile is
// never an empty rectangle even before playback starts.
import QtQuick
import QtMultimedia
import "../../"
import "../../dashboard"

Item {
    id: root

    // Absolute path of the image or video to show.
    property string source: ""
    // Poster frame for a live entry; ignored when empty.
    property string poster: ""
    property string caption: ""
    // A live entry animates; a still one is a plain Image.
    property bool live: false
    // Owning page's viewport gate. A live tile decodes ONLY when true.
    property bool playing: false
    // Category tiles show a stacked-folder affordance and a count.
    property int stackCount: 0
    property bool active: false

    signal clicked

    readonly property string _suffix: {
        const s = String(root.source);
        const dot = s.lastIndexOf(".");
        return dot < 0 ? "" : s.slice(dot + 1).toLowerCase();
    }
    readonly property bool _isVideo: root.live && ["mp4", "mkv", "webm", "mov", "m4v", "avi"].indexOf(root._suffix) !== -1
    readonly property bool _isAnimatedImage: root.live && !root._isVideo

    implicitHeight: column.implicitHeight

    Column {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Design.spacingSm

        Rectangle {
            id: frame

            width: parent.width
            height: width
            radius: 20
            color: Colours.surfaceVariant
            clip: true

            // Poster / still image. Also the under-layer for a video tile
            // until its first frame lands.
            Image {
                id: still

                anchors.fill: parent
                asynchronous: true
                cache: true
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 480
                sourceSize.height: 480
                visible: !root._isAnimatedImage && (!root._isVideo || video.position <= 0)
                source: {
                    if (root._isVideo)
                        return root.poster.length > 0 ? ("file://" + root.poster) : "";
                    if (root._isAnimatedImage)
                        return "";
                    return root.source.length > 0 ? ("file://" + root.source) : "";
                }
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    enabled: Motion.motionEnabled
                    NumberAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }
            }

            AnimatedImage {
                id: animated

                anchors.fill: parent
                visible: root._isAnimatedImage
                asynchronous: true
                cache: false
                fillMode: Image.PreserveAspectCrop
                // Paused rather than unloaded when off-viewport: keeping the
                // source lets it resume instantly, and a paused AnimatedImage
                // costs no decode.
                playing: root._isAnimatedImage && root.playing
                source: root._isAnimatedImage && root.source.length > 0 ? ("file://" + root.source) : ""
            }

            MediaPlayer {
                id: video

                source: root._isVideo && root.source.length > 0 ? ("file://" + root.source) : ""
                loops: MediaPlayer.Infinite
                audioOutput: null
                videoOutput: sink
                // The gate. Never autoPlay — a tile that is instantiated but
                // scrolled out of view must not decode.
                onSourceChanged: if (root._isVideo && root.playing)
                    play()
            }

            VideoOutput {
                id: sink

                anchors.fill: parent
                visible: root._isVideo
                fillMode: VideoOutput.PreserveAspectCrop
            }

            // Live badge, so a still and a live tile are distinguishable
            // even in the instant before playback starts.
            Rectangle {
                visible: root.live
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: Design.spacingSm
                width: 24
                height: 24
                radius: 12
                color: Colours.surface
                opacity: 0.85

                Text {
                    anchors.centerIn: parent
                    font.family: Design.symbolFontFamily
                    font.pixelSize: 15
                    color: Colours.primary
                    text: "play_arrow"
                }
            }

            // Category affordance — how many wallpapers are behind this tile.
            Rectangle {
                visible: root.stackCount > 0
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Design.spacingSm
                width: stackRow.implicitWidth + Design.spacingSm * 2
                height: 24
                radius: 12
                color: Colours.surface
                opacity: 0.85

                Row {
                    id: stackRow

                    anchors.centerIn: parent
                    spacing: Design.spacingXs

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Design.symbolFontFamily
                        font.pixelSize: 13
                        color: Colours.onSurface
                        text: "folder_copy"
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 11
                        color: Colours.onSurface
                        text: root.stackCount
                    }
                }
            }

            // Active-wallpaper ring.
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: root.active ? 3 : 0
                border.color: Colours.primary

                Behavior on border.width {
                    enabled: Motion.motionEnabled
                    NumberAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Colours.onSurface
                opacity: hover.containsMouse ? 0.08 : 0

                Behavior on opacity {
                    enabled: Motion.motionEnabled
                    NumberAnimation {
                        duration: Motion.colourDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.colourEasing
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: root.caption
            color: Colours.onSurfaceVariant
            font.pixelSize: Design.settingsFontSub
            font.weight: Design.weightEmphasis
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    // Start and stop with the viewport gate, not with construction.
    onPlayingChanged: {
        if (!root._isVideo)
            return;
        if (root.playing)
            video.play();
        else
            video.pause();
    }
}
