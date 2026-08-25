// Dial.qml — the reusable circular-arc dial (Phase 14 Plan 06, D-36/D-39).
// Filled from 14-03's inert stub. No built-in circular gauge exists anywhere
// in Qt or Quickshell (14-RESEARCH.md's "Don't Hand-Roll" table flags this
// explicitly, so nobody wastes time hunting for one) — this is genuine
// custom `QtQuick.Shapes` geometry, written once here because the
// Performance tab's four full-size dials and the Dashboard tab's three
// mini-dials (14-08) are the same component at two sizes. That reuse is
// D-39's cross-tab design rhyme, and it is why 14-08 writes no arc geometry
// of its own.
//
// ── Design constants — consolidated onto `Design` (14-09 Task 4) ────────
// Task 2 (14-09) built the shared `Design` singleton and listed THIS file
// in its own `<files>` scope, but commit 1388516 touched six consumer
// files and skipped this one — this file still declared seven local
// literals, including the exact duplicated `"Material Symbols Rounded"`
// font-family string the consolidation existed to remove. Found and closed
// at the Task 4 render-gate change request; see 14-09-SUMMARY.md's Task 4
// section for the before/after value table and the amended Task 2 scope
// note (its "66 substitutions across 6 files" claim was accurate as far as
// it went, but under-delivered against Task 2's own declared 7-file scope
// — recorded honestly as a gap found and closed in this later session, not
// as something the original session completed).
//
// Pure value-for-value: every property NAME below is unchanged (this is a
// substitution, not a renaming pass — same discipline `Design.qml`'s own
// header states), only each RHS now reads `Design.*` instead of repeating
// the literal. `_defaultFontFamily` stays local: it is a genuine RUNTIME
// CAPABILITY READ (`Qt.application.font.family`, whatever font Qt itself
// resolves as the system default), not a design token with a contract row
// behind it — there is nothing on `Design` for it to consolidate onto.
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files. This
// component occupies IDENTICAL space in all three states: D-41's whole
// point is that widget positions never move as a function of system state,
// and a dial that shrinks when a metric is missing would break the tab's
// grid layout on exactly the machine this is being built on (no battery).
import QtQuick
import QtQuick.Shapes
import "../"

Item {
    id: root

    // ── Local design constants (see header note above) — names unchanged,
    //    values now sourced from `Design`. ──────────────────────────────
    readonly property int _spacingXs: Design.spacingXs
    readonly property int _fontHeading: Design.fontHeading
    readonly property int _fontLabel: Design.fontLabel
    readonly property int _weightEmphasis: Design.weightEmphasis
    readonly property int _weightBody: Design.weightBody
    readonly property string _symbolFontFamily: Design.symbolFontFamily
    // Runtime capability read, not a design token — stays local (see
    // header note above).
    readonly property string _defaultFontFamily: Qt.application.font.family

    // ── Public API ───────────────────────────────────────────────────────
    // What the arc sweeps to, 0..1. A `Behavior` below makes every change
    // to this property glide on the standard motion pair rather than
    // stepping — the caller (PerformanceTab) simply rebinds this to the
    // reader's latest fraction every poll; the caller never animates it.
    property real value: 0
    // quick-260821-swp (R-2): value is spatial — retargeted onto
    // spatial-move.
    Behavior on value {
        enabled: Motion.motionEnabled
        NumberAnimation {
            duration: Motion.spatialMoveDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.spatialMoveEasing
        }
    }

    property string label: ""
    // The large centre string — the CALLER formats it (e.g. through
    // SystemResources' shared formatPercent), never this component, so the
    // dial has no opinion about percentages versus rates.
    property string valueText: ""
    // The small secondary line under the caption — may be empty.
    property string detailText: ""

    // Geometry — one type serves both the Performance tab's full-size
    // dials and the Dashboard tab's mini-dials (D-39) purely by varying
    // these two.
    property int diameter: 120
    property real ringThickness: 12

    // ── Per-ring theme colour + identity icon (render-gate round 2,
    //    Caelestia-look feedback: "Rings should be different colors —
    //    derived from the current theme — to add more life") ─────────────
    // The CALLER picks which Material role this instance's ring/value-text/
    // caption-icon carry (Colours.primary for CPU, .secondary for Memory,
    // .tertiary for Storage, .error for Battery in PerformanceTab.qml) — the
    // dial itself has no opinion, same discipline as `valueText`. Track arc
    // stays the muted `Colours.surfaceVariant` regardless, so only the
    // value arc (+ centre text + caption icon) carries the accent, exactly
    // the "muted track, coloured progress" split the reference shell uses.
    property color accentColor: Colours.primary
    // Material Symbols ligature identifying the metric type (e.g. "memory",
    // "storage") — shown beside the caption at every D-41 state, since it
    // names WHAT the dial measures, not whether data arrived yet. Empty
    // string omits the icon entirely (kept optional for 14-08's mini-dials,
    // which may have no room for one).
    property string icon: ""

    // D-41 empty branch — the caller's own glyph/copy.
    property string emptySymbol: "help"
    property string emptyText: "Unavailable"

    // D-41: "populated" | "pending" | "empty"
    property string widgetState: "empty"

    // The dial publishes an implicit size (unlike the tab shells, which
    // must not — D-04 fixes the drawer frame) — a parent laying dials out
    // in a Grid gets a correct natural size without hardcoding one. Plain
    // `Item` does not auto-map `width`/`height` to `implicitWidth`/
    // `implicitHeight` the way a `Control` would, so both are bound
    // explicitly — without this a parent `Grid` would size every dial at
    // its default 0x0.
    implicitWidth: root.diameter
    implicitHeight: root.diameter + root._spacingXs + captionLine.height + detailLine.height
    width: implicitWidth
    height: implicitHeight

    // ── Geometry — the arc itself ────────────────────────────────────────
    // `Shape.CurveRenderer` antialiases the arc without multisampling —
    // the declarative shape path binds directly to `value` and repaints on
    // its own; a `Canvas` would need an explicit repaint call on every
    // sample (recorded render-gate-reversible choice, see this plan's
    // `<reversibility>`).
    Shape {
        id: dialShape
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.diameter
        height: root.diameter
        preferredRendererType: Shape.CurveRenderer

        // The track — a full sweep, always drawn in every D-41 state so
        // the ring's footprint never changes.
        ShapePath {
            id: trackArc
            strokeWidth: root.ringThickness
            strokeColor: Colours.surfaceVariant
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            Behavior on strokeColor {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }

            PathAngleArc {
                centerX: dialShape.width / 2
                centerY: dialShape.height / 2
                radiusX: (root.diameter - root.ringThickness) / 2
                radiusY: (root.diameter - root.ringThickness) / 2
                startAngle: 0
                sweepAngle: 360
                moveToStart: true
            }
        }

        // The value arc — starts at twelve o'clock (-90 degrees in this
        // API's convention) and sweeps clockwise by `360 * value`. A
        // sweep of 0 (pending/empty callers always pass `value: 0`) simply
        // draws nothing, so no separate state gating is needed here — the
        // D-41 branch logic lives entirely in what the caller feeds
        // `value`, and in the centre/caption text below.
        ShapePath {
            id: valueArc
            strokeWidth: root.ringThickness
            strokeColor: root.accentColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            Behavior on strokeColor {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }

            PathAngleArc {
                centerX: dialShape.width / 2
                centerY: dialShape.height / 2
                radiusX: (root.diameter - root.ringThickness) / 2
                radiusY: (root.diameter - root.ringThickness) / 2
                startAngle: -90
                sweepAngle: 360 * root.value
                moveToStart: true
            }
        }
    }

    // ── Centre content — populated/pending/empty (D-41) ─────────────────
    // Populated: the caller's own `valueText`, heading size, demi-bold, on-
    // surface. Pending: a quiet em-dash — the slot keeps its exact size and
    // position so nothing shifts when real data lands. Empty: the caller's
    // `emptySymbol` Material Symbol ligature in place of a value.
    Text {
        id: centerText
        anchors.centerIn: dialShape
        text: root.widgetState === "populated" ? root.valueText
            : root.widgetState === "pending" ? "—" : root.emptySymbol
        font.family: root.widgetState === "empty" ? root._symbolFontFamily : root._defaultFontFamily
        font.pixelSize: root._fontHeading
        font.weight: root._weightEmphasis
        // Populated: the ring's own accent colour, not a neutral — this is
        // round 2's "more life" feedback landing on the centre figure too,
        // not just the arc. Pending/empty stay the subdued neutral.
        color: root.widgetState === "populated" ? root.accentColor : Colours.onSurfaceVariant
        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.colourDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.colourEasing
            }
        }
    }

    // ── Caption + detail — below the ring, both height-reserved so
    //    switching between states never shifts the dial's own footprint or
    //    anything laid out beneath it. The caption is now an icon+label
    //    row (round 2, Caelestia-look): the icon names WHAT this dial
    //    measures and carries the same accent as the ring, at every D-41
    //    state — only the caller's `emptyText`/`label` text beside it
    //    changes with state, exactly as before. ─────────────────────────
    Row {
        id: captionLine
        anchors.top: dialShape.bottom
        anchors.topMargin: root._spacingXs
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.ceil(root._fontLabel * 1.5)
        spacing: root._spacingXs / 2

        Text {
            visible: root.icon !== ""
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: root.icon
            font.family: root._symbolFontFamily
            font.pixelSize: root._fontLabel
            color: root.accentColor
        }

        Text {
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            // Empty replaces the caption with the caller's own quiet copy
            // ("No battery" for the battery dial) — the ONLY D-41 branch
            // that changes this text.
            text: root.widgetState === "empty" ? root.emptyText : root.label
            font.pixelSize: root._fontLabel
            font.weight: root._weightBody
            color: Colours.onSurfaceVariant
        }
    }

    Text {
        id: detailLine
        anchors.top: captionLine.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.ceil(font.pixelSize * 1.5)
        verticalAlignment: Text.AlignVCenter
        // Only populated ever shows a detail line — pending/empty leave it
        // blank but still occupying its reserved height.
        text: root.widgetState === "populated" ? root.detailText : ""
        font.pixelSize: root._fontLabel
        font.weight: root._weightBody
        color: Colours.onSurfaceVariant
    }
}
