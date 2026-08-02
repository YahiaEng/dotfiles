// PanelDialog.qml — Phase 15's shared standalone-panel frame (PANEL-06,
// D-15-02, D-15-03). Every panel this phase and Phase 16 add (audio, wifi,
// bluetooth) is constructed FROM this type, never a bespoke `PanelWindow`:
// this is the one place a panel's layer posture, header band, Advanced
// button, focus grab, Esc handling and entrance cascade are declared.
//
// ── add-alongside (assumption-delta record, land verbatim per 15-02-PLAN.md
//    <decision_records>) ─────────────────────────────────────────────────
// The QML shell's surface identity is pluralizing: `Dashboard.qml` was the
// only summonable layer surface, and this phase adds three more. The
// generalized noun is **summonable layer surface** and `PanelDialog` is its
// promoted representation — but only for **new** surfaces. `Dashboard.qml`
// is deliberately **not** refolded onto `PanelDialog` this phase: it is
// Phase-14 render-gate-passed with an open UAT item, the milestone's
// additive-only constraint forbids the churn, and D-15-02 already rejected
// drawer restructuring for exactly this reason. **Accepted debt.** What
// would force a later promote: any change that must land identically on
// all four surfaces — a shared dismissal-semantics change, a focus-grab
// model change, or a second surface wanting the drawer's tab chrome.
//
// Layer posture is copied from Dashboard.qml and parameterized (D-15-03
// inherits D-03 verbatim): anchors.top only, exclusiveZone 0, bottom-only
// rounding, WlrKeyboardFocus.OnDemand, HyprlandFocusGrab dismiss. Height and
// width are FIXED (D-15-07) — no content-derived sizing, no Behavior on
// implicitWidth/implicitHeight — because all three panels this phase adds
// have unbounded scrollable content (audio streams / visible networks /
// paired plus discovered devices).
//
// ── D-15-07 — the D-05 scroll exemption is WIDER than Phase 14 predicted
//    (land verbatim per 15-02-PLAN.md <decision_records>, quoted again in
//    the SUMMARY) ────────────────────────────────────────────────────────
// D-05 anticipated "Phase 15's per-app mixer list is the expected first
// legitimate exemption" — but the exemption recorded here is wider: **all
// three** panels scroll, because all three have unbounded content (audio
// streams / visible networks / paired plus discovered devices), unlike the
// drawer's four tabs, which D-05 audited as bounded. The exemption
// therefore covers `PanelDialog`'s body slot for every instance, not just
// the audio one, and the fixed frame height that makes it necessary is
// D-15-07's own decisive argument: a wifi scan populates progressively, so
// a content-sized panel would grow under the cursor mid-scan, moving the
// blur region and the click-outside hit zone.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"

PanelWindow {
    id: panelWindow

    // ── Public contract surface (15-02-PLAN.md <artifacts_produced>) ────
    // Renamed or removed only with an explicit decision — 15-03..15-09 and
    // Phase 16 all consume this surface by name.
    signal dismissRequested()
    property string panelTitle: ""
    property string panelGlyph: ""
    property string namespaceSuffix: ""
    property string advancedLabel: "Advanced"
    property var advancedCommand: []
    property bool advancedAvailable: true
    property string advancedUnavailableReason: ""
    default property alias body: bodyContent.data
    readonly property int panelWidth: 850
    readonly property int panelHeight: 620
    readonly property var panelStates: ["populated", "pending", "empty", "failed"]

    // ── Noted additions (15-02-PLAN.md <artifacts_produced> "Additions to
    //    that surface") ──────────────────────────────────────────────────
    property var bodyCascadeBands: []
    readonly property int headerHeight: 72
    readonly property int panelTopMargin: 10
    readonly property int cornerRadius: 28

    // ── D-15-09 fourth-state vocabulary — only `populated` and `empty` are
    //    exercised this plan; `pending`/`failed` are declared in
    //    `panelStates` and mapped in `stateColour()` but render nowhere
    //    yet (15-04/05/06's job). `readonly` because this tracer never
    //    needs to flip it — every panel this plan ships stays `populated`.
    readonly property string bodyState: "populated"
    // Generic placeholder copy/glyph, overridable per-instance by a later
    // panel file (plain `property`, not `readonly`) so 15-04/05/06 can
    // supply their own "no networks found" / "no paired devices" copy
    // without restructuring this block — the mechanism is generic, only
    // this plan's default text is.
    property string emptyStateGlyph: "info"
    property string emptyStateText: "Nothing to show"
    // D-15-06's adjacency truth, made explicit rather than incidental: a
    // 72px header band and a 40px Advanced button vertically centre to
    // exactly 16px (Design.spacingMd) of non-interactive header band above
    // the button's hit region. Anyone retuning headerHeight or the
    // button's own height must re-derive this and keep it >= spacingMd, or
    // a press aimed at the frame's top-right corner (where a close button
    // would sit on another surface) can land on the Advanced button
    // instead of doing nothing.
    readonly property int advancedTopInset: (headerHeight - advancedButton.height) / 2

    function stateColour(state) {
        switch (state) {
        case "populated": return Colours.onSurface;
        case "pending": return Colours.primary;
        case "empty": return Colours.onSurfaceVariant;
        case "failed": return Colours.error;
        default: return Colours.onSurface;
        }
    }

    function requestDismiss() {
        panelWindow.dismissRequested();
    }

    // Esc routes through this rather than straight to requestDismiss() so a
    // later panel (15-05's wifi PSK row, D-15-14's two-stage Esc) can give
    // itself a first-press-collapses/second-press-dismisses behaviour by
    // overriding this one function instead of restructuring the frame's key
    // handling. Default body just dismisses.
    function handleEscape() {
        panelWindow.requestDismiss();
    }

    // ── Layer posture (D-15-03 inherits Dashboard.qml's D-03 verbatim) ──
    anchors.top: true
    margins.top: panelWindow.panelTopMargin
    implicitWidth: panelWindow.panelWidth
    implicitHeight: panelWindow.panelHeight
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-" + panelWindow.namespaceSuffix
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"

    // ── Design-derived constants, re-declared exactly as Dashboard.qml's
    //    own D-06/UI-SPEC block so a panel body reads them off
    //    `panelWindow` the same way MediaTab.qml reads them off
    //    `dashboardWindow`. ─────────────────────────────────────────────
    readonly property int spacingXs: Design.spacingXs
    readonly property int spacingSm: Design.spacingSm
    readonly property int spacingMd: Design.spacingMd
    readonly property int spacingLg: Design.spacingLg
    readonly property int spacingXl: Design.spacingXl
    readonly property int panelPadding: Design.panelPadding
    readonly property int fontHeading: Design.fontHeading
    readonly property int fontBody: Design.fontBody
    readonly property int fontLabel: Design.fontLabel
    readonly property int weightEmphasis: Design.weightEmphasis
    readonly property int weightBody: Design.weightBody
    readonly property real lineHeightTight: 1.2
    readonly property real lineHeightNormal: 1.5
    readonly property int iconSizeMd: Design.iconSizeMd
    readonly property string symbolFontFamily: Design.symbolFontFamily
    readonly property color surfaceBase: Colours.surface
    readonly property real panelSurfaceOpacity: 0.78
    // 15-10 (G-15-1b): Hyprland's border-width parity number, read from the
    // one shared home (Design.qml) that Dashboard.qml's own GradientBorder
    // consumer also reads — never restated as a second literal here.
    readonly property int borderWidth: Design.borderWidth

    // ── Background (bottom-only rounding, D-15-03/D-03) ─────────────────
    Rectangle {
        id: background
        anchors.fill: parent
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: panelWindow.cornerRadius
        bottomRightRadius: panelWindow.cornerRadius
        color: Qt.rgba(panelWindow.surfaceBase.r, panelWindow.surfaceBase.g, panelWindow.surfaceBase.b, panelWindow.panelSurfaceOpacity)

        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    // ── Animated gradient rim (15-10, G-15-1b) — matches Hyprland's own
    //    window border exactly as Dashboard.qml's own rim does, so all
    //    three panels read as part of the same desktop rather than as
    //    foreign surfaces. Declared AFTER `background` so it paints on top
    //    of the translucent surface, and BEFORE `content` so it never
    //    overlays the header band or the Advanced button — byte-for-byte
    //    the same position Dashboard.qml:387 occupies relative to its own
    //    background/content pair. Radii are handed across from the SAME
    //    `panelWindow.cornerRadius` the `background` Rectangle above uses,
    //    so the rim and the surface can never disagree about the frame's
    //    shape.
    GradientBorder {
        anchors.fill: parent
        borderWidth: panelWindow.borderWidth
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: panelWindow.cornerRadius
        bottomRightRadius: panelWindow.cornerRadius
    }

    // ── Dismissal (D-15-20): HyprlandFocusGrab clears the drawer's own
    //    grab too if it happens to be open — a verified per-compositor
    //    platform constraint (11-QUICKSHELL-EVIDENCE Finding 2). ─────────
    HyprlandFocusGrab {
        id: grab
        windows: [ panelWindow ]
        active: true
        onCleared: panelWindow.requestDismiss()
    }

    // ── D-15-08's entrance cascade — reuses D-21's existing stagger token,
    //    so motion.json does not grow and Phase 12's D-25 semantic-layer
    //    growth policy is not re-opened. ──────────────────────────────────
    readonly property Cascade entranceCascade: Cascade {}

    Component.onCompleted: {
        panelWindow.entranceCascade.bands = [headerIdentity, advancedButton].concat(panelWindow.bodyCascadeBands);
        panelWindow.entranceCascade.armed = true;
        panelWindow.entranceCascade.run();
    }

    // ── Content root (Esc dismiss) ───────────────────────────────────────
    Item {
        id: content
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: panelWindow.handleEscape()
        Component.onCompleted: content.forceActiveFocus()

        // ── Header band (PANEL-06) ───────────────────────────────────────
        Item {
            id: headerBand
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: panelWindow.headerHeight

            Row {
                id: headerIdentity
                anchors.left: parent.left
                anchors.leftMargin: panelWindow.panelPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: panelWindow.spacingSm

                Text {
                    font.family: panelWindow.symbolFontFamily
                    font.pixelSize: panelWindow.iconSizeMd
                    text: panelWindow.panelGlyph
                    color: Colours.onSurface
                }
                Text {
                    text: panelWindow.panelTitle
                    font.pixelSize: panelWindow.fontHeading
                    font.weight: panelWindow.weightEmphasis
                    color: Colours.onSurface
                }
            }

            // ── Advanced button — plain labeled button in surfaceVariant,
            //    never accent-toned (D-15-06: Advanced is a wayfinding link
            //    out of the panel, not the panel's primary action). No
            //    close button — dismissal inherits D-10's set. ────────────
            Item {
                id: advancedButton
                anchors.right: parent.right
                anchors.rightMargin: panelWindow.panelPadding
                anchors.verticalCenter: parent.verticalCenter
                height: 40
                width: advancedLabelText.implicitWidth + panelWindow.spacingLg * 2

                // ── D-15-22 present-but-disabled treatment ───────────────
                // When the target app is absent the button stays laid out
                // at IDENTICAL geometry (never hidden, never collapsed —
                // the header must not reflow based on host state): the
                // fill/label drop to a disabled opacity, and the tooltip
                // swaps to the reason text (UI-SPEC's "{App name} is not
                // installed" copywriting row) instead of the normal
                // wayfinding hint. The MouseArea itself is deliberately
                // left `enabled: true` — a fully disabled MouseArea also
                // stops receiving hover, which would make the reason
                // UNREACHABLE by hover, directly contradicting UI-SPEC E7's
                // "the reason is legible before the press, not after."
                // "A press does nothing at all" is guaranteed instead by
                // `launchAdvanced()`'s own early-return guard below — press
                // suppression and hover-reachability are two different
                // requirements and are satisfied by two different guards
                // on purpose.
                readonly property real disabledOpacity: 0.38

                Rectangle {
                    id: advancedRect
                    anchors.fill: parent
                    radius: height / 2
                    color: Colours.surfaceVariant
                    opacity: panelWindow.advancedAvailable ? 1 : advancedButton.disabledOpacity
                }
                Text {
                    id: advancedLabelText
                    anchors.centerIn: parent
                    text: panelWindow.advancedLabel
                    font.pixelSize: panelWindow.fontBody
                    color: Colours.onSurfaceVariant
                    opacity: panelWindow.advancedAvailable ? 1 : advancedButton.disabledOpacity
                }
                MouseArea {
                    id: advancedMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: panelWindow.launchAdvanced()
                    ToolTip.visible: advancedMouseArea.containsMouse
                    ToolTip.text: panelWindow.advancedAvailable ? "Open " + panelWindow.advancedLabel.toLowerCase() + " settings" : panelWindow.advancedUnavailableReason
                    ToolTip.delay: Design.tooltipDelayMs
                }
            }
        }

        // ── Body slot (D-15-07's scroll exemption) ───────────────────────
        Flickable {
            id: bodyFlick
            anchors.top: headerBand.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: panelWindow.panelPadding
            clip: true
            contentHeight: bodyContent.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: bodyContent
                width: bodyFlick.width
                spacing: panelWindow.spacingMd
            }
        }

        // ── D-15-09 empty-state placeholder — the D-41/D-15-26 case 4
        //    "quiet Material Symbol plus one line" grammar, rendered only
        //    when `bodyState` is `"empty"`. Only `populated` and `empty`
        //    are exercised this plan; the audio panel's default is
        //    `populated`, so this stays invisible in Task 1/2's own
        //    render gate and is here purely as the shared mechanism
        //    15-04/05/06 render into when a panel's list is genuinely
        //    empty (wifi off, no paired devices, …). Anchored to the same
        //    region as `bodyFlick` rather than living inside `bodyContent`
        //    itself, since `bodyContent` is the panel-supplied `body` slot
        //    — this placeholder is the frame's own fallback, not content a
        //    panel file writes into. ─────────────────────────────────────
        Column {
            id: emptyStatePlaceholder
            anchors.centerIn: bodyFlick
            visible: panelWindow.bodyState === "empty"
            spacing: panelWindow.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: panelWindow.emptyStateGlyph
                font.family: panelWindow.symbolFontFamily
                font.pixelSize: panelWindow.iconSizeMd
                color: panelWindow.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: panelWindow.emptyStateText
                font.pixelSize: panelWindow.fontBody
                color: panelWindow.stateColour("empty")
            }
        }
    }

    // ── Advanced launch (T-15-02's whole mitigation) ─────────────────────
    // `advancedCommand` is assigned exactly once per panel file as a
    // literal array of double-quoted string literals. This Process object
    // never appends to it, never interpolates an element, never joins it
    // into a string, and never hands it to a shell interpreter.
    Process {
        id: advancedProcess
        command: panelWindow.advancedCommand
    }

    // startDetached() — NOT a lifetime-bound `running` assignment — because
    // LazyLoader destroys this whole surface on dismiss, and a
    // lifetime-bound child is SIGTERM'd with it (QuickToggles.qml's own
    // recorded live reproduction of exactly that failure for the Dark
    // chip). D-15-02 makes the race certain here because every Advanced
    // click opens a focus-stealing app whose focus grab tears this surface
    // down. startDetached() is also what makes the PANEL-05 concurrency
    // truth hold: a second press starts a second independent child and
    // cannot kill the first.
    function launchAdvanced() {
        if (!panelWindow.advancedAvailable)
            return;
        advancedProcess.startDetached();
    }
}
