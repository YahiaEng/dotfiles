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
// property only. It never reads the raw remote art URL field and never
// invokes the resolver: that boundary stays exactly where MediaBackend.qml and
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
import QtQuick.Shapes
import QtQuick.Effects
import "../"
import "../dashboard"

SectionPopout {
    id: root

    property var mediaBackend: null

    // ── CavaService ownership (D-21-05/06, 21-06) — this popout is
    // D-21-05's second visualiser host, sharing the SAME CavaService
    // singleton MediaTab.qml claims (top-level modules/qmldir
    // registration, Plan 01) — one shared audio process, not two. This
    // body is mounted/unmounted by PopoutTrigger.qml's own LazyLoader
    // (`active: PopoutController.openSection === sectionId`), which is
    // exactly "the popout is genuinely visible" / "stopped being
    // visible" — the same construction/destruction-as-visibility
    // trigger MediaTab.qml's Component.onCompleted/onDestruction
    // already uses (D-14's per-summon LazyLoader lifecycle), no
    // separate visibility computation needed here either. Never gated
    // on playback state — no pause term anywhere in this file.
    Component.onCompleted: CavaService.claim()
    Component.onDestruction: CavaService.release()

    // Plain circular mask path — the shape the cover art uses after the
    // operator reversed D-21-02 on 2026-08-16. Duplicated from MediaTab.qml
    // for the same file-lexical reason its cookie twin below is duplicated.
    // Two 180-degree arcs, since a single 360-degree SVG arc is degenerate.
    function _circlePath(w, h) {
        var cx = w / 2;
        var cy = h / 2;
        var r = Math.min(w, h) / 2;
        return "M " + (cx - r).toFixed(2) + "," + cy.toFixed(2) +
            " A " + r.toFixed(2) + "," + r.toFixed(2) + " 0 1 0 " + (cx + r).toFixed(2) + "," + cy.toFixed(2) +
            " A " + r.toFixed(2) + "," + r.toFixed(2) + " 0 1 0 " + (cx - r).toFixed(2) + "," + cy.toFixed(2) + " Z";
    }

    // ── D-21-02 (REVERSED 2026-08-16, retained unused): the same hand-authored 12-lobe cookie path MediaTab.qml
    // builds, duplicated here rather than shared — QML functions are
    // file-lexical (the same reason MediaTab.qml's own header gives for
    // its locally-duplicated design constants), and this file has no
    // singleton of its own to hang a shared helper on. Identical
    // geometry logic; only the caller's w/h differ (this popout's own
    // _artSize, not the tab's artCircleSize).
    function _cookiePath(w, h) {
        var lobes = 12;
        var cx = w / 2;
        var cy = h / 2;
        var outerR = w / 2;
        var innerR = outerR * 0.86;
        var step = Math.PI / lobes;

        var points = [];
        for (var k = 0; k < lobes * 2; k++) {
            var angle = k * step;
            var r = (k % 2 === 0) ? outerR : innerR;
            points.push({
                x: cx + r * Math.cos(angle),
                y: cy + r * Math.sin(angle)
            });
        }

        var dx = points[1].x - points[0].x;
        var dy = points[1].y - points[0].y;
        var chord = Math.sqrt(dx * dx + dy * dy);
        var arcR = chord * 0.6;

        var path = "M " + points[0].x.toFixed(2) + "," + points[0].y.toFixed(2);
        for (var i = 1; i <= points.length; i++) {
            var p = points[i % points.length];
            path += " A " + arcR.toFixed(2) + "," + arcR.toFixed(2) + " 0 0 1 " + p.x.toFixed(2) + "," + p.y.toFixed(2);
        }
        path += " Z";
        return path;
    }

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

    // ── Visualiser geometry (D-21-01/03/05, 21-06) — the same 60-bar
    // radial ring MediaTab.qml carries, ported rather than re-invented.
    // Derived from THIS popout's own _artSize (48) rather than copied
    // from the tab's absolute pixel values (which target a 220px art
    // slot) — this thumbnail is much smaller, so its ring needs its own
    // proportions to read at this scale. Bar count, cap style, and the
    // two-role outline/primary silence-to-live transition are all
    // UNCHANGED from the tab (one behaviour across both surfaces).
    readonly property int _visualiserBarCount: 60
    readonly property real _ringGap: 3
    readonly property real _ringRadius: root._artSize / 2 + root._ringGap
    // Scaled up with MediaTab.qml on the same operator "too subtle"
    // feedback, kept proportional to this popout's much smaller art.
    readonly property real _visualiserMaxExtension: 8
    readonly property real _visualiserMinSliver: 1.5
    readonly property real _visualiserBarStrokeWidth: 1.5
    // Same measured perceptual curve as MediaTab.qml — see the long note
    // there. Duplicated per-file for the same file-lexical reason the
    // other visualiser constants are duplicated.
    readonly property real _visualiserResponseExponent: 0.45
    // The outer Item's side length needed to contain the ring at full
    // amplitude without clipping: art diameter plus the gap and max
    // extension on both sides.
    readonly property int _ringSlotSize: root._artSize + Math.ceil((root._ringGap + root._visualiserMaxExtension) * 2)

    Row {
        id: mediaRow
        visible: root.bodyState === "populated"
        width: parent.width
        spacing: Design.spacingSm

        // ── Album art + visualiser ring — D-21-05 (21-06). This file
        //    previously had neither a mask nor a ring (a plain
        //    Image.PreserveAspectCrop inside a small corner-radius
        //    Rectangle); both are new here, ported from MediaTab.qml
        //    rather than invented. `artSlot` is now the OUTER ring-bearing
        //    wrapper (sized `_ringSlotSize`, bigger than the art itself so
        //    the bars have room to extend outward); the actual masked art
        //    lives in the inner `artContainer`, centred within it. Kept
        //    the id `artSlot` so `mediaTextColumn`'s width/anchor math
        //    below needs no further edit. ───────────────────────────────
        Item {
            id: artSlot
            width: root._ringSlotSize
            height: root._ringSlotSize

            // D-21-01/03/05: 60 radial bars, identical construction to
            // MediaTab.qml's — one straight radial segment per bar, angle
            // deterministic from index, silence/failure both falling
            // through to the same minimum-sliver outline silhouette.
            Shape {
                id: mediaRing
                anchors.fill: parent
                asynchronous: true
                preferredRendererType: Shape.CurveRenderer

                // Same Repeater/ShapePath limitation as MediaTab.qml: a
                // Repeater cannot instantiate ShapePath (not an Item), and
                // fails silently to zero bars. Item-wrapper + data.push is
                // the documented workaround (Qt Forum 104917).
                Repeater {
                    model: root._visualiserBarCount

                    delegate: Item {
                        id: popoutBarDelegate

                        readonly property int barIndex: index

                        Component.onCompleted: mediaRing.data.push(popoutBarDelegate.barPath)

                        readonly property ShapePath barPath: ShapePath {
                        id: popoutVisualiserBar
                        fillColor: "transparent"
                        strokeWidth: root._visualiserBarStrokeWidth
                        capStyle: ShapePath.RoundCap

                        readonly property int barIndex: popoutBarDelegate.barIndex
                        readonly property real angleRad: (popoutVisualiserBar.barIndex * (360 / root._visualiserBarCount) - 90) * Math.PI / 180

                        readonly property bool hasLiveData: CavaService.streaming
                            && CavaService.bars.length > popoutVisualiserBar.barIndex
                        readonly property real amplitude: popoutVisualiserBar.hasLiveData
                            ? Math.max(0, Math.min(1, CavaService.bars[popoutVisualiserBar.barIndex]))
                            : 0
                        readonly property real shapedAmplitude: Math.pow(popoutVisualiserBar.amplitude, root._visualiserResponseExponent)
                        readonly property real outerRadius: root._ringRadius
                            + root._visualiserMinSliver
                            + popoutVisualiserBar.shapedAmplitude * (root._visualiserMaxExtension - root._visualiserMinSliver)

                        startX: artSlot.width / 2 + root._ringRadius * Math.cos(popoutVisualiserBar.angleRad)
                        startY: artSlot.height / 2 + root._ringRadius * Math.sin(popoutVisualiserBar.angleRad)

                        PathLine {
                            x: artSlot.width / 2 + popoutVisualiserBar.outerRadius * Math.cos(popoutVisualiserBar.angleRad)
                            y: artSlot.height / 2 + popoutVisualiserBar.outerRadius * Math.sin(popoutVisualiserBar.angleRad)
                        }

                        strokeColor: (popoutVisualiserBar.hasLiveData && popoutVisualiserBar.amplitude > 0)
                            ? Colours.primary
                            : Colours.outline

                        Behavior on strokeColor {
                            enabled: Motion.motionEnabled
                            ColorAnimation {
                                duration: Motion.standardDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.standardEasing
                            }
                        }
                        }
                    }
                }
            }

            Item {
                id: artContainer
                anchors.centerIn: parent
                width: root._artSize
                height: root._artSize

                // Placeholder fill — invisible on its own, composited
                // through the same 12-lobe mask as the loaded art below
                // (one mask source, not one per state), same as
                // MediaTab.qml's artBackground/artMaskedBackground pair.
                Rectangle {
                    id: artBackground
                    anchors.fill: parent
                    color: Colours.surfaceVariant
                    visible: false
                }

                Image {
                    id: artImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: root._artSize
                    sourceSize.height: root._artSize
                    // This file's own trust boundary (see header): reads
                    // only the backend's already-resolved artPath, never
                    // the raw remote art URL — unchanged by this task.
                    source: (root.mediaBackend && root.mediaBackend.artPath) ? ("file://" + root.mediaBackend.artPath) : ""
                    // Painted only through the MultiEffect below.
                    visible: false
                }

                // D-21-02: hand-authored 12-lobe mask, same construction
                // as MediaTab.qml's artMaskShape (root._cookiePath() +
                // PathSvg, no shape-library import). `layer.enabled: true`
                // is load-bearing — an invisible item with no layer has no
                // paint node for MultiEffect.maskSource to read alpha
                // from (round-4 finding, MediaTab.qml's header).
                Shape {
                    id: artMaskShape
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true
                    asynchronous: true
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        // Never painted — only alpha coverage is read.
                        // Sourced from a real role, not a hex literal.
                        fillColor: Colours.onSurface
                        strokeColor: "transparent"

                        PathSvg {
                            // Operator reversal of D-21-02 (2026-08-16) —
                            // circle restored, masking mechanism untouched.
                            path: root._circlePath(artContainer.width, artContainer.height)
                        }
                    }
                }

                MultiEffect {
                    id: artMaskedBackground
                    anchors.fill: parent
                    source: artBackground
                    maskEnabled: true
                    maskSource: artMaskShape
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }

                MultiEffect {
                    id: artMaskedImage
                    anchors.fill: parent
                    source: artImage
                    maskEnabled: true
                    maskSource: artMaskShape
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
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
        // F4 (quick task 260812-69w): the only child of bodyColumn with
        // neither width: parent.width nor a centring anchor — mediaRow,
        // the progress line and multiPlayerText all set width: parent.width;
        // this Row's own three buttons need CENTRING, not stretching, so it
        // takes the opposite treatment. anchors.horizontalCenter is legal on
        // a Column child (Column positions only the vertical axis); centerIn
        // and any vertical anchor are not and would draw "Cannot specify ...
        // anchors for items inside Column" and silently break the
        // positioner. Measured before this fix: transportRow.x=0 while
        // bodyColumn.width=328 — flush left, not centred.
        anchors.horizontalCenter: parent.horizontalCenter
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
