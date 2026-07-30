// Cascade.qml — D-21's summon-only entrance cascade runner (Phase 14 Plan 09).
//
// Non-visual (QtObject root — never contributes geometry to the frame
// D-04 fixes). One reusable instance, mounted once on Dashboard.qml's
// window root, fed the currently-active pane's own `cascadeBands` list on
// every summon. No tab file gets animation code of its own; this is the
// only place a duration or an easing curve is read for the entrance.
//
// ── API ──────────────────────────────────────────────────────────────────
// `bands`         — ordered list of top-level band items, read order
//                   first to last, supplied by whichever tab is showing.
// `armed`         — true when a cascade is owed. The drawer root sets it
//                   true on every summon; this runner consumes it exactly
//                   once, before any animation starts (D-21's first
//                   fence — a tab switch later in the same surface
//                   lifetime finds it already false and does nothing).
// `tabIndex`      — set by the caller immediately before `run()`, purely
//                   so the recorded run marker below names which tab
//                   cascaded.
// `riseDistance`  — the ONE number this file declares: how far each band
//                   starts below its resting position, taken from the
//                   drawer's own spacing scale at the medium step
//                   (14-UI-SPEC.md's "md" token / D-06's 4px-grid regime
//                   — every sibling tab file already declares this exact
//                   value locally under the same name, per the
//                   consolidation-deferred precedent 14-08-SUMMARY.md
//                   recorded). Geometry, not motion: motion-lint's CHECK B
//                   refuses a raw duration/easing literal, never a
//                   spacing constant.
// `runCount`      — incremented on every real run — the tab-switch
//                   fence's countable trace, independent of the log line
//                   below.
// `run()`         — the entry point.
// `reset()`       — restores every band to full opacity and zero offset
//                   (the `off`-scale collapse's mechanism).
//
// ── Names read off the Motion singleton ─────────────────────────────────
// Exactly five: the stagger pair's duration/easing aliases, the
// emphasized-in pair's duration/easing aliases, and the motion-enabled
// flag. Never `Motion.motionScale` — that name resolves at run time on
// this build but is a motion-lint CHECK A dangling reference (12-06/14-02's
// recorded divergence), so the `off`/`reduced` collapse is proven by
// observed behaviour (D-21's second fence) rather than by reading it.
import QtQuick
import "../"

QtObject {
    id: root

    property var bands: []
    property bool armed: false
    property int tabIndex: -1
    readonly property int riseDistance: 16
    property int runCount: 0

    // A bare translate, instantiated fresh per cascaded band and assigned
    // as that band's transform list — animating a layout-managed item's
    // `y` directly fights the anchors/Column that already positions it; a
    // transform sits outside that layout entirely and returns to zero.
    property Component _translateFactory: Component {
        Translate {}
    }

    // One sequential-then-parallel animation per band: a pause of `index`
    // stagger-offset units, then opacity and the translate's `y` running
    // together for the emphasized-in duration on the emphasized-in curve.
    // A Component, not a static child — each band needs its own instance
    // with its own target/bandIndex, and this root has no fixed number of
    // bands to declare them for ahead of time.
    property Component _animFactory: Component {
        SequentialAnimation {
            id: seqAnim

            property var targetBand: null
            property var targetTranslate: null
            property int bandIndex: 0

            PauseAnimation {
                duration: seqAnim.bandIndex * Motion.staggerOffsetDuration
            }
            ParallelAnimation {
                NumberAnimation {
                    target: seqAnim.targetBand
                    property: "opacity"
                    to: 1
                    duration: Motion.emphasizedInDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.emphasizedInEasing
                }
                NumberAnimation {
                    target: seqAnim.targetTranslate
                    property: "y"
                    to: 0
                    duration: Motion.emphasizedInDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.emphasizedInEasing
                }
            }
        }
    }

    // Restores every band to full opacity and zero offset. This is the
    // `off`-scale collapse's whole mechanism, and stands alone for
    // anything else that ever needs the bands settled immediately.
    function reset() {
        for (var i = 0; i < root.bands.length; i++) {
            var band = root.bands[i];
            if (!band)
                continue;
            band.opacity = 1;
            if (band.transform) {
                for (var j = 0; j < band.transform.length; j++) {
                    var t = band.transform[j];
                    if (t && t.y !== undefined)
                        t.y = 0;
                }
            }
        }
    }

    // The entry point. Consumes `armed` before touching a single band —
    // that consumption, done unconditionally and first, IS D-21's first
    // fence in its entirety. No second guard keyed on tab index or
    // elapsed time exists here; a second guard would only hide a bug in
    // this one.
    function run() {
        if (!root.armed)
            return;
        root.armed = false;

        if (!Motion.motionEnabled) {
            // D-21's `off` collapse: no cascade, every band at its final
            // state immediately — delivered by the existing motion-scale
            // plumbing, not a branch of its own.
            root.reset();
            return;
        }

        for (var i = 0; i < root.bands.length; i++) {
            var band = root.bands[i];
            if (!band)
                continue;

            if (band.transform && band.transform.length > 0) {
                // A sibling plan already declared a transform on this
                // band — do not clobber it. Leave the band at its
                // resting state; recorded by name in the SUMMARY.
                console.log("cascade: skip band-with-transform tab=" + root.tabIndex + " index=" + i);
                continue;
            }

            var translateObj = root._translateFactory.createObject(band, { "y": root.riseDistance });
            band.transform = [translateObj];
            band.opacity = 0;

            var anim = root._animFactory.createObject(root, {
                "targetBand": band,
                "targetTranslate": translateObj,
                "bandIndex": i
            });
            anim.finished.connect(anim.destroy);
            anim.start();
        }

        root.runCount++;
        // The fence's countable trace, grepped verbatim by this plan's own
        // verify block and read by Task 4's human gate.
        console.log("cascade: run tab=" + root.tabIndex + " bands=" + root.bands.length);
    }
}
