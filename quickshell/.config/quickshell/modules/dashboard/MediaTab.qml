// MediaTab.qml — the MD3 full player (Phase 14 Plan 05, D-35): cover art,
// title/artist/album type stack, seek slider, Material Symbols transport,
// volume row, player-switcher chips, and the D-41 in-place empty register.
//
// Root type Item, filled via anchors.fill: parent by the Loader Dashboard.qml
// places it in — actual rendered geometry always matches whatever size its
// Loader currently has, including mid-resize-animation.
//
// `implicitWidth`/`implicitHeight` below are D-04's "no implicit size"
// prohibition, deliberately reversed at 14-03's render gate (checkpoint
// feedback 2026-07-29, see 14-03-SUMMARY.md's Deviations): Dashboard.qml
// reads these as an advisory hint to compute the drawer's own animated frame
// target — a pure metadata read, independent of this item's actual rendered
// size. They are now derived from this file's real layout's own natural
// size (`playerColumn.implicitHeight` reactively, plus this file's own
// panel padding) rather than the 900x420 placeholder 14-03 shipped.
//
// ── Design constants — NOT read off `dashboardWindow` ───────────────────
// Same mechanism gap QuickToggles.qml's header already records: `id`-based
// lookup in QML is lexical to the declaring FILE, and `MediaTab` is a
// separate registered component type instantiated inside `dashboardWindow`'s
// object tree, not textually nested inside Dashboard.qml — so a bare
// `dashboardWindow.spacingLg`-style reference from this file would not
// resolve. Per 14-05-PLAN.md's own fallback instruction, this file declares
// its own copies of exactly the constants it needs, sourced from
// 14-UI-SPEC.md's Spacing Scale/Typography tables and 14-02-SUMMARY.md's
// recorded font family/FILL-axis verdict — consolidating every tab onto one
// shared constants surface is left to 14-08's composition pass.
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files. This tab is
// ONE layout with two content states (D-41's whole point): every slot below
// occupies the same space and sits at the same position whether or not a
// player exists — there is no separate empty screen.
import QtQuick
import QtQuick.Controls
import "../"

Item {
    id: root

    anchors.fill: parent

    // ── Constants mirrored from 14-UI-SPEC.md (see header comment above —
    //    this file cannot reach dashboardWindow's copies). ────────────────
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 16
    readonly property int panelPadding: 24 // 14-UI-SPEC.md Spacing Scale "lg"

    readonly property int fontBody: 16
    readonly property int fontLabel: 12
    readonly property int weightEmphasis: Font.DemiBold
    readonly property int weightBody: Font.Normal

    readonly property int iconSizeMd: 24
    // Exact installed family string, per 14-02-SUMMARY.md's registration.
    readonly property string symbolFontFamily: "Material Symbols Rounded"
    // 14-02-SUMMARY.md's live-measured verdict: `fill-axis-renders` — Qt
    // 6.11.1 genuinely drives this font's FILL variable axis on this build.
    // If a future build ever regresses this, flip this one property to fix
    // the lit-state language back to a static glyph weight.
    readonly property bool fillAxisAvailable: true

    // ── This tab's own layout constants ─────────────────────────────────
    readonly property int artSize: 200
    readonly property int artRadius: 16
    readonly property int preferredContentWidth: 360
    readonly property int controlRowHeight: 32
    readonly property int chipRowHeight: 36
    readonly property int timeLabelWidth: 36
    readonly property int transportSize: 44
    readonly property int transportEmphasizedSize: 60

    // D-41 register vocabulary, carried for register consistency across
    // every modules/dashboard/ file (same precedent as QuickToggles.qml).
    readonly property var widgetStateVocabulary: ["populated", "pending", "empty"]
    // Mirrors the backend's own register so the D-41 vocabulary reads the
    // same from either file.
    readonly property string widgetState: root.mediaBackend ? root.mediaBackend.widgetState : "empty"

    property var mediaBackend: null

    // Advisory content-driven size hint (D-04 superseded) — read by
    // Dashboard.qml's activeContentWidth/activeContentHeight, not by this
    // item's own actual rendered geometry (still anchors.fill: parent
    // above). Reactive to playerColumn's own natural height so a band that
    // disappears (the volume row, when the active player exposes no
    // volume) is reflected honestly rather than left as a stale estimate.
    implicitWidth: root.preferredContentWidth + root.panelPadding * 2
    implicitHeight: playerColumn.implicitHeight + root.panelPadding * 2

    readonly property bool hasPlayer: root.mediaBackend ? root.mediaBackend.hasPlayer : false

    function _formatTime(totalSeconds) {
        var s = Math.max(0, Math.floor(totalSeconds || 0));
        var m = Math.floor(s / 60);
        var sec = s % 60;
        return m + ":" + (sec < 10 ? "0" + sec : sec);
    }

    // Drag-suppression flag (the seek band's own truth-driven exception):
    // while dragging, the slider stops following the incoming one-second
    // stream tick, and on release issues one seek through the backend.
    property bool seekDragging: false

    // ── One layout, two content states — the whole of D-41 ──────────────
    Column {
        id: playerColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.panelPadding
        spacing: root.spacingMd

        // ── 1. Cover art ─────────────────────────────────────────────────
        Item {
            id: artSlot
            width: root.artSize
            height: root.artSize
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                id: artContainer
                anchors.fill: parent
                radius: root.artRadius
                clip: true
                color: Colours.surfaceVariant

                Image {
                    id: artImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    // media-art-resolve.sh's `http(s)://` branch keys its
                    // on-disk cache path off a sha256 of the FULL url, so
                    // that path genuinely is stable per-track. Its
                    // `file://` branch instead passes the third-party
                    // player's own path straight through with no
                    // repo-owned cache-path guarantee of its own — the
                    // payload's `art` field never reveals which branch
                    // produced it, so the two cannot be told apart here.
                    // Firefox's own MPRIS art-thumbnail file (the case
                    // observed live on this machine) is outside this
                    // repo's control, and a wrongly-cached reused path
                    // would show the previous track's art — a failure that
                    // reads as a metadata bug, not a caching one. `cache:
                    // false` is therefore the universally-safe choice:
                    // it never shows stale art, and the only cost is a
                    // redundant decode of bytes the resolver script (and,
                    // for `file://`, the player itself) already cached on
                    // disk.
                    cache: false
                    source: (root.mediaBackend && root.mediaBackend.artPath) ? ("file://" + root.mediaBackend.artPath) : ""
                }

                // Quiet placeholder — shows while loading, when the art
                // path is empty, and when the image fails to load. Three
                // cases, one visual, zero layout shift: whenever the image
                // is not in its Ready state, this glyph is what occupies
                // the slot.
                Text {
                    id: artPlaceholder
                    anchors.centerIn: parent
                    visible: artImage.status !== Image.Ready
                    text: "music_note"
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.artSize * 0.4
                    color: Colours.onSurfaceVariant
                }
            }
        }

        // ── 2. Type stack — fixed height, per-field fallbacks ───────────
        Column {
            id: typeStack
            anchors.left: parent.left
            anchors.right: parent.right
            height: titleLine.height + artistLine.height + albumLine.height + root.spacingXs * 2
            spacing: root.spacingXs

            Text {
                id: titleLine
                width: parent.width
                elide: Text.ElideRight
                text: root.hasPlayer ? (root.mediaBackend.displayTitle || "") : "Nothing playing"
                font.pixelSize: root.fontBody
                font.weight: root.hasPlayer ? root.weightEmphasis : root.weightBody
                color: root.hasPlayer ? Colours.onSurface : Colours.onSurfaceVariant
            }
            // Artist/album stay structurally present (default `visible:
            // true`) rather than toggling `visible` directly — a Column
            // positioner excludes an invisible child from layout entirely,
            // which would shift the sibling below it upward and collapse
            // the reserved slot, the opposite of D-41's "hidden without
            // collapsing" rule. An empty `text` renders nothing but keeps
            // occupying its normal line-height slot, which is the actual
            // in-place-hide behaviour this block needs.
            Text {
                id: artistLine
                width: parent.width
                elide: Text.ElideRight
                text: (root.hasPlayer && root.mediaBackend.displayArtist !== "") ? root.mediaBackend.displayArtist : ""
                font.pixelSize: root.fontBody
                font.weight: root.weightBody
                color: Colours.onSurfaceVariant
            }
            Text {
                id: albumLine
                width: parent.width
                elide: Text.ElideRight
                text: (root.hasPlayer && root.mediaBackend.displayAlbum !== "") ? root.mediaBackend.displayAlbum : ""
                font.pixelSize: root.fontLabel
                font.weight: root.weightBody
                color: Colours.onSurfaceVariant
            }
        }

        // ── 3. Seek band — present-but-disabled when unseekable ─────────
        Row {
            id: seekRow
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.controlRowHeight
            spacing: root.spacingSm

            Text {
                id: elapsedLabel
                width: root.timeLabelWidth
                height: parent.height
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                text: root._formatTime(root.mediaBackend ? root.mediaBackend.positionSeconds : 0)
                font.pixelSize: root.fontLabel
                color: Colours.onSurfaceVariant
            }

            Slider {
                id: seekSlider
                width: seekRow.width - elapsedLabel.width - totalLabel.width - root.spacingSm * 2
                height: parent.height
                from: 0
                to: Math.max(1, root.mediaBackend ? root.mediaBackend.lengthSeconds : 1)
                value: root.seekDragging ? seekSlider.value : (root.mediaBackend ? root.mediaBackend.positionSeconds : 0)
                enabled: root.hasPlayer && root.mediaBackend.canSeek
                onPressedChanged: {
                    if (pressed) {
                        root.seekDragging = true;
                    } else if (root.seekDragging) {
                        root.seekDragging = false;
                        if (root.mediaBackend)
                            root.mediaBackend.seekTo(seekSlider.value);
                    }
                }

                background: Rectangle {
                    x: seekSlider.leftPadding
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    width: seekSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Colours.surfaceVariant
                    opacity: seekSlider.enabled ? 1 : 0.38

                    Rectangle {
                        width: seekSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Colours.primary
                    }
                }
                handle: Rectangle {
                    x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    width: 16
                    height: 16
                    radius: 8
                    color: Colours.primary
                    opacity: seekSlider.enabled ? 1 : 0.38
                }
            }

            Text {
                id: totalLabel
                width: root.timeLabelWidth
                height: parent.height
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                text: root._formatTime(root.mediaBackend ? root.mediaBackend.lengthSeconds : 0)
                font.pixelSize: root.fontLabel
                color: Colours.onSurfaceVariant
            }
        }

        // ── 4. Transport row — previous / play-pause / next ─────────────
        component TransportButton: Item {
            id: btn

            property string glyph: ""
            property bool emphasized: false
            property bool controlEnabled: true
            property bool pressedState: false
            signal activated()

            readonly property int diameter: emphasized ? root.transportEmphasizedSize : root.transportSize
            width: diameter
            height: diameter

            // D-22's truth-driven rule: only the glyph choice (bound by the
            // caller to the backend's playing predicate) reflects real
            // state. This fillProgress is purely an instant MD3 press
            // acknowledgment on the emphasized control, never a truth
            // signal itself.
            property real fillProgress: (btn.emphasized && root.fillAxisAvailable && btn.pressedState) ? 1 : 0
            Behavior on fillProgress {
                enabled: Motion.motionEnabled
                NumberAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }

            Rectangle {
                id: circle
                anchors.fill: parent
                radius: width / 2
                clip: true
                color: btn.emphasized ? Colours.primary : "transparent"
                opacity: btn.controlEnabled ? 1 : 0.38
                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }

                Rectangle {
                    id: rippleCircle
                    width: 0
                    height: 0
                    radius: width / 2
                    color: btn.emphasized ? Colours.onPrimary : Colours.onSurface
                    opacity: 0
                }

                Text {
                    anchors.centerIn: parent
                    text: btn.glyph
                    font.family: root.symbolFontFamily
                    font.pixelSize: btn.emphasized ? root.iconSizeMd + 8 : root.iconSizeMd
                    font.variableAxes: root.fillAxisAvailable ? { "FILL": btn.fillProgress } : ({})
                    color: btn.emphasized ? Colours.onPrimary : Colours.onSurfaceVariant
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    enabled: btn.controlEnabled
                    onPressed: (mouse) => {
                        btn.pressedState = true;
                        if (!Motion.motionEnabled)
                            return;
                        const d = Math.max(circle.width, circle.height) * 2;
                        rippleCircle.x = mouse.x - d / 2;
                        rippleCircle.y = mouse.y - d / 2;
                        rippleCircle.width = 0;
                        rippleCircle.height = 0;
                        rippleCircle.opacity = 0.16;
                        rippleGrowAnim.stop();
                        rippleFadeAnim.stop();
                        rippleGrowAnim.to = d;
                        rippleGrowAnim.start();
                    }
                    onReleased: btn.pressedState = false
                    onCanceled: btn.pressedState = false
                    onClicked: btn.activated()

                    NumberAnimation {
                        id: rippleGrowAnim
                        target: rippleCircle
                        properties: "width,height"
                        duration: Motion.emphasizedInDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedInEasing
                        onFinished: rippleFadeAnim.start()
                    }
                    NumberAnimation {
                        id: rippleFadeAnim
                        target: rippleCircle
                        property: "opacity"
                        to: 0
                        duration: Motion.emphasizedOutDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedOutEasing
                    }
                }
            }
        }

        Row {
            id: transportRow
            anchors.horizontalCenter: parent.horizontalCenter
            height: root.transportEmphasizedSize
            spacing: root.spacingMd

            TransportButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "skip_previous"
                emphasized: false
                controlEnabled: root.hasPlayer
                onActivated: if (root.mediaBackend) root.mediaBackend.previousTrack()
            }
            TransportButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: (root.mediaBackend && root.mediaBackend.playing) ? "pause" : "play_arrow"
                emphasized: true
                controlEnabled: root.hasPlayer
                onActivated: if (root.mediaBackend) root.mediaBackend.playPause()
            }
            TransportButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "skip_next"
                emphasized: false
                controlEnabled: root.hasPlayer
                onActivated: if (root.mediaBackend) root.mediaBackend.nextTrack()
            }
        }

        // ── 5. Volume band — ABSENT (not disabled) with no volume ───────
        // A real player-capability limit signalled by the payload's own
        // sentinel, asymmetric with the seek band's present-but-disabled
        // treatment above — recorded here rather than left to look like an
        // inconsistency.
        Row {
            id: volumeRow
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.controlRowHeight
            spacing: root.spacingSm
            visible: root.hasPlayer && root.mediaBackend.hasVolume

            Text {
                width: root.iconSizeMd
                height: parent.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "volume_up"
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                color: Colours.onSurfaceVariant
            }

            Slider {
                id: volumeSlider
                width: volumeRow.width - root.iconSizeMd - root.spacingSm
                height: parent.height
                from: 0
                to: 1
                value: root.mediaBackend ? root.mediaBackend.volumeLevel : 0
                onPressedChanged: {
                    if (!pressed && root.mediaBackend)
                        root.mediaBackend.setVolume(volumeSlider.value);
                }

                background: Rectangle {
                    x: volumeSlider.leftPadding
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: volumeSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Colours.surfaceVariant

                    Rectangle {
                        width: volumeSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Colours.primary
                    }
                }
                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: 16
                    height: 16
                    radius: 8
                    color: Colours.primary
                }
            }
        }

        // ── 6. Player-switcher chips — keeps its slot at 0/1/N players ──
        component PlayerChip: Item {
            id: chip

            property string chipLabel: ""
            property bool chipActive: false
            signal activated()

            implicitWidth: label.implicitWidth + root.spacingMd * 2
            implicitHeight: root.chipRowHeight

            Rectangle {
                id: chipBg
                anchors.fill: parent
                radius: height / 2
                color: chip.chipActive ? Colours.primary : Colours.surfaceVariant
                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: chip.chipLabel
                    elide: Text.ElideRight
                    font.pixelSize: root.fontLabel
                    color: chip.chipActive ? Colours.onPrimary : Colours.onSurfaceVariant
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !chip.chipActive
                    onClicked: chip.activated()
                }
            }
        }

        Row {
            id: playerChipRow
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.chipRowHeight
            spacing: root.spacingSm

            Repeater {
                model: root.mediaBackend ? root.mediaBackend.players : []
                delegate: PlayerChip {
                    height: playerChipRow.height
                    chipLabel: modelData.label || modelData.id || ""
                    chipActive: !!modelData.active
                    onActivated: if (root.mediaBackend) root.mediaBackend.selectPlayer(modelData.id)
                }
            }
        }
    }
}
