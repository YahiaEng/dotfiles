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
//
// ── `runExit()` (Phase 20, power-menu THIRD revision, 2026-08-15) ────────
// The mirror of `run()`: sweeps every band back OUT (opacity 1->0,
// transform 0->its entrance start value) instead of in. An opt-in ENTRY
// POINT, not a default behaviour change — every existing consumer (all
// seven `PanelDialog`/Dashboard/Overview/etc. tabs) never calls this
// function, so nothing about their own dismissal changes; only a caller
// that explicitly invokes `runExit()` (PowerMenu.qml, this pass) gets an
// animated exit at all.
//
// Deliberately NOT staggered per band the way `run()` is — every band
// exits in PARALLEL, all at once. Two reasons: (1) the entrance's stagger
// exists to draw the eye across six pills arriving one after another,
// which is a want, not a need — nothing about dismissal needs the same
// per-band reveal rhythm; (2) PowerMenu.qml's own Bug-2 fix gates the
// session action's own process start on this animation finishing, so
// stacking `bands.length * staggerOffsetDuration` on top of the exit
// duration would add real, avoidable latency to Suspend/Hibernate/
// Shutdown. A single un-staggered `Motion.emphasizedOutDuration` (150ms
// fallback) is the whole added delay, not a stagger-multiplied one.
//
// Reuses `Motion.emphasizedOutDuration`/`emphasizedOutEasing` — the
// existing "exit" pair (already consumed by the OSD/power-menu dismiss
// per `20-UI-SPEC.md`'s own Motion table), not a reversed copy of the
// in-curve and not a new token; `motion-lint` has one more consumer of an
// existing name, not a new name to check.
//
// Reuses whatever transform object `run()` already attached to a band
// (left resting at `y`/`angle` 0 once the entrance finished) rather than
// creating a second one — falls back to creating one fresh only if a band
// was never animated in at all (e.g. `Motion.motionEnabled` was off at
// entrance time, so `run()` took its `reset()` branch and attached no
// transform).
//
// `_activeAnims` / `_stopActiveAnims()` exist for exactly one edge case:
// D-20-36 deliberately leaves entrance and input readiness unserialised,
// so a click-outside/Escape dismissal can arrive WHILE the entrance
// cascade is still mid-flight. Without this guard, `runExit()` would start
// a second animation on the same band's `opacity`/transform property
// while the first was still running — two animations fighting the same
// property is a visual glitch, not merely untidy. `runExit()` stops (and
// discards) any such in-flight entrance animation first, so the exit
// continues smoothly from wherever the band actually was, never from a
// value the entrance never reached.
import QtQuick
import "../"

QtObject {
    id: root

    property var bands: []
    property bool armed: false
    property int tabIndex: -1
    readonly property int riseDistance: 16
    property int runCount: 0

    // ── Exit support (third revision) — see the header note above. ──────
    // Fired once, after every band's own exit animation has finished (or
    // immediately, synchronously, under the `off`-motion collapse) — the
    // single synchronisation point a caller needs to know "the surface is
    // now actually done animating out."
    signal exitFinished()
    // Bookkeeping for `_stopActiveAnims()` — every SequentialAnimation
    // `run()` starts is tracked here while in flight, so a `runExit()`
    // that arrives mid-entrance can stop them cleanly instead of letting
    // two animations fight the same band property. Never read/written by
    // anything outside `run()`/`runExit()`/`_stopActiveAnims()`.
    property var _activeAnims: []
    property int _exitPending: 0

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
                // quick-260821-swp (R-2): transformProperty holds "y" or
                // "angle" (both spatial) at createObject() time — retargeted
                // onto spatial-in. motion-lint-allow: runtime-computed-property
                // (the target property name is not a literal here, so
                // CHECK E's static scanner cannot classify this line; read
                // by a human instead — both possible values are spatial).
                NumberAnimation {
                    target: seqAnim.targetTransform
                    property: seqAnim.transformProperty
                    to: 0
                    duration: Motion.spatialInDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.spatialInEasing
                }
            }
        }
    }

    // Exit counterpart of `_animFactory` above — a `ParallelAnimation`, not
    // a `SequentialAnimation` wrapping a `PauseAnimation`, because exit is
    // deliberately un-staggered (see the header note's latency reasoning).
    // `toValue` is per-instance (0->riseDistance for a translate band,
    // 0->ringSweepAngle for a rotation band) since, unlike the entrance
    // (which always targets 0), the exit target differs by transform kind.
    property Component _exitAnimFactory: Component {
        ParallelAnimation {
            id: exitAnim

            property var targetBand: null
            property var targetTransform: null
            property string transformProperty: "y"
            property real toValue: 0

            NumberAnimation {
                target: exitAnim.targetBand
                property: "opacity"
                to: 0
                duration: Motion.emphasizedOutDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedOutEasing
            }
            // quick-260821-swp (R-2): transformProperty holds "y" or
            // "angle" (both spatial) at createObject() time — retargeted
            // onto spatial-out. motion-lint-allow: runtime-computed-property
            // (the target property name is not a literal here, so CHECK E's
            // static scanner cannot classify this line; read by a human
            // instead — both possible values are spatial).
            NumberAnimation {
                target: exitAnim.targetTransform
                property: exitAnim.transformProperty
                to: exitAnim.toValue
                duration: Motion.spatialOutDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.spatialOutEasing
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
            root._activeAnims.push(anim);
            anim.finished.connect(root._makeEntranceFinishedHandler(anim));
            anim.start();
        }

        root.runCount++;
        // The fence's countable trace, grepped verbatim by this plan's own
        // verify block and read by Task 4's human gate.
        console.log("cascade: run tab=" + root.tabIndex + " bands=" + root.bands.length + " circularMotion=" + root.circularMotion);
    }

    // Returns a closure bound to ONE `anim` instance — written as a factory
    // function rather than an inline `for`-loop closure because `var`
    // (this file's own convention throughout) is function-scoped, not
    // block-scoped: an inline closure inside the `run()` loop above would
    // capture the SAME `anim` variable across every iteration and every
    // handler would end up referencing only the last-created animation.
    // Binding `anim` as this function's own parameter gives each returned
    // closure its own independent copy.
    function _makeEntranceFinishedHandler(anim) {
        return function() {
            var idx = root._activeAnims.indexOf(anim);
            if (idx >= 0)
                root._activeAnims.splice(idx, 1);
            anim.destroy();
        };
    }

    // Stops and discards every still-running entrance animation — see the
    // header note's `_activeAnims` paragraph for why `runExit()` must do
    // this before starting its own animations.
    function _stopActiveAnims() {
        for (var i = 0; i < root._activeAnims.length; i++) {
            var a = root._activeAnims[i];
            if (a) {
                a.stop();
                a.destroy();
            }
        }
        root._activeAnims = [];
    }

    // The exit entry point — see the header note above for the full
    // reasoning (un-staggered, `emphasizedOut`-family tokens, transform
    // reuse). Emits `exitFinished()` exactly once, after every band's own
    // exit animation completes, or immediately/synchronously under the
    // `off`-motion collapse (mirroring `run()`'s own `reset()` branch).
    function runExit() {
        root._stopActiveAnims();

        if (!Motion.motionEnabled || root.bands.length === 0) {
            root.exitFinished();
            return;
        }

        root._exitPending = 0;
        for (var i = 0; i < root.bands.length; i++) {
            var band = root.bands[i];
            if (!band)
                continue;

            var transformObj;
            var transformProperty;
            var toValue;
            var hasExistingTransform = band.transform && band.transform.length > 0;
            if (root.circularMotion && band.ringPivot !== undefined) {
                transformObj = hasExistingTransform ? band.transform[0] : root._rotationFactory.createObject(band, {
                    "origin.x": band.ringPivot.x,
                    "origin.y": band.ringPivot.y,
                    "angle": 0
                });
                transformProperty = "angle";
                toValue = root.ringSweepAngle;
            } else {
                transformObj = hasExistingTransform ? band.transform[0] : root._translateFactory.createObject(band, { "y": 0 });
                transformProperty = "y";
                toValue = root.riseDistance;
            }
            if (!hasExistingTransform)
                band.transform = [transformObj];

            root._exitPending++;
            var anim = root._exitAnimFactory.createObject(root, {
                "targetBand": band,
                "targetTransform": transformObj,
                "transformProperty": transformProperty,
                "toValue": toValue
            });
            anim.finished.connect(root._makeExitFinishedHandler(anim));
            anim.start();
        }

        // The fence's countable trace, mirroring `run()`'s own
        // "cascade: run" line so a reader greps one prefix for both
        // directions.
        console.log("cascade: run-exit tab=" + root.tabIndex + " bands=" + root.bands.length + " circularMotion=" + root.circularMotion);
    }

    // Same per-instance-closure reasoning as `_makeEntranceFinishedHandler`
    // above, plus the `_exitPending` countdown that turns N per-band
    // completions into the single `exitFinished()` a caller awaits.
    function _makeExitFinishedHandler(anim) {
        return function() {
            root._exitPending--;
            anim.destroy();
            if (root._exitPending <= 0)
                root.exitFinished();
        };
    }
}
