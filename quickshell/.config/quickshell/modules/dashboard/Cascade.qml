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
//
// ── `circularMotion` (Phase 20, power-menu second revision, 2026-08-15) ──
// An opt-in EXTENSION of the entrance mechanism above, not a second one.
// Every existing consumer (PanelDialog.qml's tabs) leaves `circularMotion`
// at its default `false` and is byte-unchanged in behaviour — the
// straight-line translate-rise path below is untouched code, just now one
// of two branches `run()` can take per band rather than the only one.
//
// When `circularMotion: true`, a band that declares its own `ringPivot`
// (a `point`, in the band's OWN local coordinate space, naming where its
// ring's centre sits — see PowerMenu.qml's pill delegate for the worked
// example) sweeps into its resting position by ROTATING `ringSweepAngle`
// degrees toward 0 around that pivot, instead of translating `riseDistance`
// px toward 0 on the y axis. `band.ringPivot` is read via duck-typing —
// this file never imports or references PowerMenu.qml, it only checks
// whether the property exists on whatever Item was handed to it, exactly
// the same "read what the band offers, do not assume its type" discipline
// `band.transform`'s own skip-check below already establishes. A band with
// no `ringPivot` (e.g. a centre label or a warning chip, neither of which
// has a meaningful rotation centre) is unaffected and still takes the
// existing translate path even while `circularMotion` is true for the
// Cascade instance as a whole — the choice is per-band, not per-instance.
import QtQuick
import "../"

QtObject {
    id: root

    property var bands: []
    property bool armed: false
    property int tabIndex: -1
    readonly property int riseDistance: 16
    property int runCount: 0

    // Opt-in — see the header note above. Default false preserves every
    // existing consumer's behaviour unchanged.
    property bool circularMotion: false
    // ringSweepAngle (30°) — geometry, not motion (like riseDistance
    // above; motion-lint's CHECK B is anchored on `duration`/`easing`-named
    // properties, not a plain angle). Half of the 60° spacing between
    // adjacent power-menu pills (Design.sessionRingRadius's own derivation
    // elsewhere) — enough arc to read clearly as a rotational sweep into
    // place without a pill's START position reaching all the way into the
    // NEXT pill's own resting slot, which a full 60° sweep would.
    readonly property int ringSweepAngle: 30

    // A bare translate, instantiated fresh per cascaded band and assigned
    // as that band's transform list — animating a layout-managed item's
    // `y` directly fights the anchors/Column that already positions it; a
    // transform sits outside that layout entirely and returns to zero.
    property Component _translateFactory: Component {
        Translate {}
    }

    // A bare rotation, instantiated fresh per cascaded band when
    // `circularMotion` applies to it — mirrors `_translateFactory` above
    // exactly, just a different Qt Quick transform type. `origin.x`/
    // `origin.y` are set per-instance at createObject() time from the
    // band's own `ringPivot`, the same "set per-instance, not declared
    // here" idiom `_translateFactory`'s own `y` already uses.
    property Component _rotationFactory: Component {
        Rotation {}
    }

    // One sequential-then-parallel animation per band: a pause of `index`
    // stagger-offset units, then opacity and the transform's own moving
    // property (`y` for a translate-rise band, `angle` for a
    // circular-motion band) running together for the emphasized-in
    // duration on the emphasized-in curve. A Component, not a static
    // child — each band needs its own instance with its own
    // target/bandIndex, and this root has no fixed number of bands to
    // declare them for ahead of time. `transformProperty` is what makes
    // one Component serve both transform kinds — set per-instance at
    // createObject() time, read here as a plain string, since
    // `NumberAnimation.property` already accepts a dynamic string name.
    property Component _animFactory: Component {
        SequentialAnimation {
            id: seqAnim

            property var targetBand: null
            property var targetTransform: null
            property string transformProperty: "y"
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
                    target: seqAnim.targetTransform
                    property: seqAnim.transformProperty
                    to: 0
                    duration: Motion.emphasizedInDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.emphasizedInEasing
                }
            }
        }
    }

    // Restores every band to full opacity and zero offset/angle. This is
    // the `off`-scale collapse's whole mechanism, and stands alone for
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
                    if (t && t.angle !== undefined)
                        t.angle = 0;
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

            var transformObj;
            var transformProperty;
            if (root.circularMotion && band.ringPivot !== undefined) {
                transformObj = root._rotationFactory.createObject(band, {
                    "origin.x": band.ringPivot.x,
                    "origin.y": band.ringPivot.y,
                    "angle": root.ringSweepAngle
                });
                transformProperty = "angle";
            } else {
                transformObj = root._translateFactory.createObject(band, { "y": root.riseDistance });
                transformProperty = "y";
            }
            band.transform = [transformObj];
            band.opacity = 0;

            var anim = root._animFactory.createObject(root, {
                "targetBand": band,
                "targetTransform": transformObj,
                "transformProperty": transformProperty,
                "bandIndex": i
            });
            anim.finished.connect(anim.destroy);
            anim.start();
        }

        root.runCount++;
        // The fence's countable trace, grepped verbatim by this plan's own
        // verify block and read by Task 4's human gate.
        console.log("cascade: run tab=" + root.tabIndex + " bands=" + root.bands.length + " circularMotion=" + root.circularMotion);
    }
}
