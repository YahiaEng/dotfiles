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
// WEBP DOES NOT DECODE ON A HOST MISSING qt6-imageformats, and that is a
// host gap, not a bug in this file. Measured 2026-08-26 with QImageReader
// through PySide6: `supportedImageFormats()` returns bmp/cur/gif/ico/jfif/
// jpeg/jpg/pbm/pgm/png/ppm/svg/svgz/xbm/xpm — no webp — and
// `QImageReader("tracer-probe.webp").canRead()` is false with "Unsupported
// image format". /usr/lib/qt6/plugins/imageformats/ held only gif, ico,
// jpeg and svg. So a `.webp` live wallpaper silently shows its extracted
// poster frame for ever and never animates, and a `.webp` STILL wallpaper
// cannot render in this shell at all. The library currently holds exactly
// one webp (`catppuccin/live/tracer-probe.webp`), which is why this went
// unnoticed. Do not "fix" it here — the missing piece is a Qt image format
// plugin on the host.
//
// THE PLUGIN IS NAMED AND CONFIRMED (quick task 260826-qr1). It is Arch's
// `qt6-imageformats`, now in install.sh's PACMAN_PKGS. This was previously
// filed as an unconfirmed CANDIDATE because the package description
// advertises only "TIFF, MNG, TGA, WBMP" — that description is simply
// incomplete. Listing the real 6.11.2-1 package contents shows seven
// plugins, libqwebp.so among them, and `Depends On: libwebp` corroborates.
// Read the contents, never the blurb. A host installed before that line
// existed still needs `sudo pacman -S --needed qt6-imageformats` once; a
// fresh install.sh run covers it. The gif path was never affected and is
// measured good (1920x1080, 150 frames, every frame full-size).
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

    // ── Keyboard reachability (quick task 260826-wl3) ────────────────────
    // The same duck-typed contract every row primitive implements, so
    // Pages.qml's `_collectFocusableRows()` picks tiles up and
    // `activateContentRow()` can fire them: `focusable` marks the stop,
    // `rowFocused` is written externally by the focus walker, and
    // `activated` is the member it duck-types on (declared as a signal,
    // exactly as NavRow does — `typeof` a QML signal is "function").
    //
    // This is why the owning grids are eager `Grid`s and not virtualising
    // `GridView`s: a GridView creates delegates lazily, so the collected
    // focus set would silently change size as the user scrolls and every
    // index after the change would point at a different tile.
    readonly property bool focusable: true
    property bool rowFocused: false

    signal activated
    signal clicked

    onActivated: root.clicked()

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

            // ── Cover-size + centre, rather than trusting the toolkit's crop
            //    (operator live pass, quick task 260826-oyu, defect 3).
            //
            //    "The animated thumbnail does not show the entire live
            //    wallpaper, only a left side portion of it." Captured the
            //    running carousel to confirm it, and that surface is its own
            //    control: its frame is EXACTLY 16:9 (WallpaperMode.qml:220)
            //    and all three live sources measure 1920x1080 (ffprobe: SAR
            //    1:1, DAR 16:9), so `PreserveAspectCrop` there should be a
            //    no-op. The poster `Image` neighbours rendered the full
            //    frame; the tile actually playing was zoomed with its right
            //    edge cut. Identical geometry, identical fillMode value —
            //    the ELEMENT TYPE was the only variable.
            //
            //    The symptom is left-anchored overflow: content sized larger
            //    than the frame and pinned at x=0. So stop asking the element
            //    to crop, and state the geometry instead — a box sized to
            //    COVER the frame, centred in it, with the image fitted inside
            //    that box. When the aspect is right this is pixel-identical
            //    to a correct PreserveAspectCrop; when it is wrong the
            //    overflow is split evenly instead of all falling off one
            //    side, so the worst case is a centred crop rather than a
            //    corner of the image.
            //
            //    `sourceSize` is measured-reliable for the gif on this host
            //    (QImageReader: 1920x1080, and all 150 frames full-size, no
            //    partial-rect frames). The 16:9 fallback covers a source Qt
            //    cannot read at all — which is not hypothetical here, see the
            //    webp note in this file's header.
            AnimatedImage {
                id: animated

                readonly property real srcAspect: (sourceSize.width > 0 && sourceSize.height > 0) ? (sourceSize.width / sourceSize.height) : (16 / 9)

                anchors.centerIn: parent
                width: Math.max(parent.width, parent.height * srcAspect)
                height: Math.max(parent.height, parent.width / srcAspect)
                visible: root._isAnimatedImage
                asynchronous: true
                cache: false
                fillMode: Image.PreserveAspectFit
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

            // Same treatment as `animated` above, and for the same reason —
            // see its header. `sourceRect` is VideoOutput's own view of the
            // decoded frame, so it is the aspect authority here; it is an
            // empty rect until the first frame lands, which the guard covers.
            VideoOutput {
                id: sink

                readonly property real srcAspect: (sourceRect.width > 0 && sourceRect.height > 0) ? (sourceRect.width / sourceRect.height) : (16 / 9)

                anchors.centerIn: parent
                width: Math.max(parent.width, parent.height * srcAspect)
                height: Math.max(parent.height, parent.width / srcAspect)
                visible: root._isVideo
                fillMode: VideoOutput.PreserveAspectFit
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
                // Active (this IS the wallpaper) reads as a solid ring;
                // keyboard focus as a thinner one, so a focused tile that
                // is also active still shows it is active.
                border.width: root.active ? 3 : (root.rowFocused ? 2 : 0)
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
