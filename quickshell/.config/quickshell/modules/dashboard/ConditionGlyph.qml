// ConditionGlyph.qml — the single-or-layered weather condition glyph
// (Phase 14 Plan 10, Task 1).
//
// ── What this replaces ────────────────────────────────────────────────────
// The three condition-glyph call sites in `WeatherTab.qml` (hero, every
// hour-strip cell, every day-row cell) were each a bare `Text` rendering one
// ligature name in one resolved colour, plus a `MouseArea` tooltip carried
// separately at each site. This type folds all three into one reusable
// component with one new capability: for exactly two composite conditions
// (`partly_cloudy_day`, `partly_cloudy_night`) it can render a coloured base
// glyph with a second, differently-coloured glyph layered on top — the
// two-tone experiment Phase 14's closing render gate asked for. Every other
// condition renders exactly as it did before this type existed.
//
// ── Why the root is a Text, not an Item ──────────────────────────────────
// Deliberate, not stylistic. The three sites this type replaces were each a
// `Text` whose own font metrics set the height its parent column or row laid
// out. A `Text` root reproduces that implicit size by construction — no
// implicit-size formula is declared anywhere in this file — rather than by a
// formula someone has to keep in sync with the font. The overlay lives as a
// CHILD of this root: QML's `Text` does not size itself from its children
// (unlike `Column`/`Row`), so the overlay is painted above the root's own
// glyph and contributes nothing to the root's implicit size. Those two facts
// together are what make the layered stack occupy the exact same box as the
// single glyph it replaces.
//
// ── The revert ────────────────────────────────────────────────────────────
// `layeringEnabled` (default true) is the experiment's whole revert path.
// With it false — or with `symbolName` outside the two-entry composite map
// below — the root renders `symbolName` in `singleToneColor` at `pixelSize`
// with `baseFillAxis`: byte-equivalent to what every condition already does
// today, and the overlay child stays invisible. This is the ONLY colour path
// for every non-composite condition, and it is the whole of the revert for
// the composite ones. See 14-10-SUMMARY.md for the recorded before/after
// observation of flipping this switch.
//
// ── The tuning knobs ──────────────────────────────────────────────────────
// `baseScale`, `overlayScale`, `overlayOffsetXFraction`,
// `overlayOffsetYFraction` and `overlayFillAxis` are all named, settable
// properties in this one file, so retuning the layered look at a future gate
// is a one-line edit here rather than a hunt across three call sites. None
// of them is a motion value (they are geometry fractions of `pixelSize`) and
// none belongs on `Design.qml` — they are specific to this one glyph family,
// the same reasoning `Design.qml`'s own header already uses for what it
// deliberately leaves out. The two colour transitions in this file reference
// `Motion.standardDuration`/`Motion.standardEasing` only — no timing value
// of any kind is written as a literal in this file.
//
// ── The composite map ─────────────────────────────────────────────────────
// Exactly two entries, keyed on the ligature name `WeatherTab.qml` already
// has at each render site (the tab never sees a raw WMO code). Every other
// condition in `WeatherPalette.qml`'s table is a single-concept icon that is
// already correctly single-coloured; a third entry here would be scope creep
// against a designer's already-balanced glyph. Base-glyph choice for each
// entry, and why:
//   - `partly_cloudy_day` -> base `wb_sunny` (NOT a ligature name
//     `WeatherBackend.qml` itself ever emits, so this plan's Task 1 confirmed
//     it renders as a real glyph in the installed font before this map was
//     written — see 14-10-SUMMARY.md's Task 1 section for the render
//     evidence. The recorded fallback, had it not rendered, was `clear_day`,
//     the ligature the backend already emits for the "Clear" condition.)
//   - `partly_cloudy_night` -> base `clear_night` (already emitted by the
//     backend for the "Clear" night condition, so already proven to render
//     on this build — its ligature target glyph is the same crescent-moon
//     shape already used for the sunset icon elsewhere on this tab).
// The overlay for both entries is the `cloud` ligature (already emitted by
// the backend for "Overcast", already proven to render) in `cloudColor`.
//
// ── Colours: never named, always injected ─────────────────────────────────
// `sunColor`, `moonColor` and `cloudColor` arrive as typed `color` inputs
// from the caller (`WeatherTab.qml`, reading `WeatherPalette.*` exactly
// once, in exactly one place). This file never names `WeatherPalette`
// anywhere — that is what keeps the singleton's documented single-consumer
// scope intact instead of widening it to a second file. `singleToneColor`
// is likewise supplied by the caller, computed exactly as it always was.
import QtQuick
import QtQuick.Controls
import "../"

Text {
    id: root

    // ── Public API ───────────────────────────────────────────────────────
    property string symbolName: ""
    property int pixelSize: 24
    property int baseFillAxis: 1
    property color singleToneColor: "transparent"
    property color sunColor: "transparent"
    property color moonColor: "transparent"
    property color cloudColor: "transparent"
    property string conditionLabel: ""
    property int tooltipDelay: 400
    property bool layeringEnabled: true

    // ── Named tuning knobs (see header note above) ─────────────────────
    // baseScale: the base glyph's size as a fraction of `pixelSize` —
    // defaults to the whole of it, so the composite base is the same size
    // as a plain single-tone glyph unless a future gate retunes it down.
    property real baseScale: 1.0
    // overlayScale: the overlay's size as a fraction of `pixelSize`.
    property real overlayScale: 0.68
    // overlayOffsetXFraction / overlayOffsetYFraction: the overlay's
    // displacement from the base's centre, as fractions of `pixelSize` —
    // fractions rather than pixels so one set of numbers works at both the
    // hero size and the small cell size instead of needing two.
    property real overlayOffsetXFraction: 0.16
    property real overlayOffsetYFraction: 0.30
    // overlayFillAxis: the overlay's own FILL weight — filled by default so
    // the cloud reads as a solid shape against the outlined/filled base.
    property int overlayFillAxis: 1

    // ── The composite map — exactly two entries (see header note) ───────
    readonly property var _compositeMap: ({
            "partly_cloudy_day": {
                base: "wb_sunny",
                color: root.sunColor
            },
            "partly_cloudy_night": {
                base: "clear_night",
                color: root.moonColor
            }
        })
    readonly property string overlaySymbolName: "cloud"

    readonly property var _composite: root._compositeMap[root.symbolName] || null
    readonly property bool isComposite: root._composite !== null
    // The actual rendering branch: layered only when both the map has this
    // condition AND the revert switch is on.
    readonly property bool _layered: root.layeringEnabled && root.isComposite

    // ── The base glyph — this Text item itself ──────────────────────────
    text: root._layered ? root._composite.base : root.symbolName
    font.family: Design.symbolFontFamily
    font.pixelSize: root._layered ? Math.round(root.pixelSize * root.baseScale) : root.pixelSize
    font.variableAxes: ({
            "FILL": root.baseFillAxis
        })
    color: root._layered ? root._composite.color : root.singleToneColor
    Behavior on color {
        enabled: Motion.motionEnabled
        ColorAnimation {
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
    }

    // ── The overlay — a child, contributes nothing to root's implicit
    //    size, painted above the base glyph only when layered ───────────
    Text {
        id: overlayGlyph
        visible: root._layered
        text: root.overlaySymbolName
        font.family: Design.symbolFontFamily
        font.pixelSize: Math.round(root.pixelSize * root.overlayScale)
        font.variableAxes: ({
                "FILL": root.overlayFillAxis
            })
        color: root.cloudColor
        anchors.horizontalCenter: root.horizontalCenter
        anchors.verticalCenter: root.verticalCenter
        anchors.horizontalCenterOffset: Math.round(root.pixelSize * root.overlayOffsetXFraction)
        anchors.verticalCenterOffset: Math.round(root.pixelSize * root.overlayOffsetYFraction)
        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    // ── The hover tooltip — moved in from the three former call sites ───
    MouseArea {
        id: conditionMouseArea
        anchors.fill: root
        hoverEnabled: true
    }
    // ThemedToolTip (quick-260821-6z1 fix wave) — replaces the bare
    // attached ToolTip shorthand; see ThemedToolTip.qml. `delay:` is
    // still driven from root.tooltipDelay, not ThemedToolTip's own
    // Design.tooltipDelayMs default, so a future caller overriding
    // root.tooltipDelay keeps working exactly as before.
    ThemedToolTip {
        visible: conditionMouseArea.containsMouse && root.conditionLabel !== ""
        text: root.conditionLabel
        delay: root.tooltipDelay
    }
}
