// Motion.qml — sibling Quickshell.Singleton to Colours.qml (D-11's pattern
// extended to motion, TOKEN-05). Read-only consumer of motion.sh's
// `motion.json` render target (~/.local/state/theme/motion.json,
// contract.json-listed, format "json") — never writes back, same
// discipline as Colours.qml (T-12-21).
//
// ── NAMING DIVERGENCE FROM 12-UI-SPEC.md / this plan's own artifact list
// (recorded per 12-06-PLAN.md's critical_handoff_from_12_05, flagged loudly
// as instructed rather than left silent) ───────────────────────────────
// 12-UI-SPEC.md and 12-06-PLAN.md's "artifacts_this_phase_produces" section
// both name these properties `standardBezier` / `emphasizedInBezier` /
// `emphasizedOutBezier`. But 12-05 ALREADY SHIPPED `motion-lint` before this
// plan ran, and its `load_qml_defs()` (hypr/.config/hypr/scripts/motion-lint,
// ~line 290) hard-codes a DIFFERENT, narrower convention derived from
// motion.json's own semantic keys: `<camelKey>Duration`, `<camelKey>Easing`,
// plus a top-level `motionEnabled`. Using "Bezier" here would make every
// `Motion.standardEasing`-shaped reference this file's own consumers need to
// write come back as a CHECK-A dangling reference in motion-lint's
// already-committed compliant/poisoned fixtures — breaking `theme-doctor`
// for everyone downstream the moment Probe.qml (Task 2) consumes it. Per
// the plan's own default-action instruction ("adopt this convention exactly
// ... keeps the gate green with no cross-plan edit"), this file adopts
// motion-lint's convention exactly. The "Easing"-named property still HOLDS
// the six-element bezier control-point array Qt's `easing.bezierCurve`
// expects — only the property NAME differs from UI-SPEC's prose, not its
// shape or its data. Not this plan's file to fix: motion-lint is owned by
// 12-05/12-07 (scope_boundary) — this divergence is recorded here AND in
// 12-06-SUMMARY.md's Deviations section for 12-07 to see.
//
// `pragma Singleton` + qmldir's `singleton` keyword are both required for
// bare `Motion.motionEnabled`-style access to resolve at all — see
// Colours.qml's header comment for the binary-verified finding (corrects
// 12-RESEARCH.md Pattern 2). Unlike Colours.qml, this file has no "X"/"onX"
// property-name pairs, so it does not need Colours.qml's split-adapter
// workaround for the separate "cannot assign a value to a signal" compiler
// bug that pairing triggers.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // D-25's trimmed semantic set this phase wires — fixed here, not
    // derived from the JSON, so a missing/empty motion.json still yields
    // three "(undefined)" rows (ui:error/E2) rather than a JS exception
    // walking an absent object.
    //
    // D-21's "stagger-offset" key (14-02) is APPENDED as the fourth entry.
    // Append order is load-bearing, not stylistic: `pairs` is read
    // POSITIONALLY by the six per-pair aliases below (pairs[0]/[1]/[2] for
    // standard/emphasized-in/emphasized-out), so inserting a new key
    // anywhere but the end re-points those existing aliases at the wrong
    // semantic entry. Any future semantic key must be appended here too.
    //
    // G-15-1's "ambient" key is APPENDED as the FIFTH entry, following that
    // same append-only discipline exactly (never insert). Unlike the four
    // entries before it, `ambient` is a continuous LOOP PERIOD, not a
    // one-shot transition — it is the corrected sweep token for the wifi
    // scan / bluetooth discovery indeterminate progress lines, which
    // previously had no correctly-scaled loop period reachable from QML at
    // all (see `ambientDuration` below).
    //
    // quick-260821-swp's three spatial keys (R-2/R-3) are APPENDED as the
    // SIXTH/SEVENTH/EIGHTH entries — never inserted, same append-only
    // discipline as every entry before them. These are the ONLY three
    // easing names a style may ever give overshoot: every spatial QML site
    // (the 40 retargeted sites plus the 8 former bar-drawer sites) binds
    // one of these three, and every other alias below (standard/
    // emphasizedIn/emphasizedOut/staggerOffset/ambient) stays monotonic in
    // every style, forever — that split is what makes a bouncing fade
    // impossible by construction rather than by a maintained list.
    //
    // 2026-08-25's "colour" key is APPENDED as the NINTH entry, same
    // append-only discipline. It is the dedicated COLOUR/effects channel
    // ported from Caelestia's shell (CAnim.qml animates every colour on
    // expressiveSlowEffects rather than on the generic standard token).
    // It joins standard/emphasizedIn/emphasizedOut/staggerOffset/ambient on
    // the permanently-monotonic side of the R-2 split: a colour must never
    // overshoot, because an overshooting colour interpolation extrapolates
    // PAST the target rather than clamping the way opacity does.
    readonly property var _pairNames: ["standard", "emphasized-in", "emphasized-out", "stagger-offset", "ambient", "spatial-in", "spatial-out", "spatial-move", "colour"]

    property bool loadHealthy: true

    FileView {
        id: motionFile
        path: Quickshell.env("HOME") + "/.local/state/theme/motion.json"
        watchChanges: true
        printErrors: true
        onFileChanged: {
            root.loadHealthy = true;
            reload();
        }
        onLoadFailed: (error) => {
            root.loadHealthy = false;
        }

        JsonAdapter {
            id: motion
            // These MUST carry motion.json's own snake_case key names.
            // JsonAdapter maps top-level JSON keys to declared properties by
            // EXACT name — there is no snake_case-to-camelCase conversion
            // (verified behaviourally in 14-09: with the state file at `off`
            // and the rendered file carrying "motion_enabled": false, a
            // camelCase `motionEnabled` property silently kept its `true`
            // default and every motion gate in the shell stayed live). The
            // `semantic` property below never showed the fault because its
            // name already matches its key exactly, which is precisely what
            // masked this for two phases. The public camelCase aliases below
            // are what every consumer and motion-lint's CHECK A read; only
            // the binding names change here.
            //
            // quick-260821-swp: `motion_scale` (a duration multiplier) is
            // replaced by `motion_style` (a curve-shape name) — the renderer
            // no longer emits `motion_scale` at all, and this binding's own
            // name change is exactly the divergence-catching mechanism the
            // comment above describes; a stale `motion_scale` property here
            // would silently keep reading `undefined` forever rather than
            // failing loud. `motion_accessibility` is new alongside it.
            property bool motion_enabled: true
            property string motion_style: "md3"
            property string motion_accessibility: "full"
            // G-15-1: the resolved multiplier itself, as a bare scalar (not
            // a duration/easing pair, so it takes no part in `_pairNames`/
            // `pairs`). QML needs this NUMBER, not just `motion_scale`'s
            // NAME, so a continuous loop-period token (`ambientDuration`
            // below) can divide the active multiplier back out and never
            // shrink its period under a smaller motion scale. Defaults to
            // 1.0 (unscaled) rather than 0 so a missing key degrades
            // safely — a 0 divisor downstream would be a division-by-zero,
            // not just an unscaled fallback (T-15-11-01).
            property real motion_multiplier: 1.0
            // Raw nested object — JsonAdapter maps only TOP-LEVEL JSON keys
            // to declared properties (verified against the installed
            // Quickshell.Io/quickshell-io.qmltypes: no nested-path mapping
            // exists). A `var` property receives motion.json's `semantic`
            // sub-object verbatim; the per-pair duration_ms/easing/bezier
            // fields are read out of it below rather than declared as their
            // own top-level JsonAdapter properties, since there is no such
            // top-level key for a value like "standardDuration" to bind to.
            property var semantic: ({})

            // DASH-10: the `indicators` bucket, same raw-nested-object shape
            // and same reason as `semantic` above — JsonAdapter maps only
            // TOP-LEVEL keys, so this receives motion.json's `indicators`
            // sub-object verbatim and the per-token fields are read out of it
            // below. Emitted to this file by lib/motion.sh as of the drawer's
            // animated gradient border, which needs the SAME `border-rotate`
            // period Hyprland's `borderangle` runs at.
            property var indicators: ({})
        }
    }

    readonly property alias motionEnabled: motion.motion_enabled
    readonly property alias motionStyle: motion.motion_style
    readonly property alias motionAccessibility: motion.motion_accessibility
    readonly property alias motionMultiplier: motion.motion_multiplier

    // True once ANY of this phase's three semantic names is present in the
    // rendered file. False for a missing-file or empty-semantic
    // motion.json — exactly ui:empty/E2's trigger for a single explicit
    // "no motion tokens loaded" row rather than three broken ones.
    readonly property bool hasMotionTokens: {
        var s = motion.semantic;
        return !!(s && Object.keys(s).length > 0);
    }

    function _camel(key) {
        return key.replace(/-([a-z0-9])/g, function (_m, c) {
            return c.toUpperCase();
        });
    }

    // One entry per D-25 semantic pair, ALWAYS three entries regardless of
    // what actually resolved (ui:partial/E2: a resolved-duration/
    // unresolved-easing pair, or vice versa, must render its own row with
    // only the broken field marked — never disappear from the list).
    readonly property var pairs: _pairNames.map(function (key) {
        var entry = (motion.semantic && motion.semantic[key]) || null;
        var durationValid = !!entry && typeof entry.duration_ms === "number"
            && isFinite(entry.duration_ms) && entry.duration_ms > 0;
        // A Qt BezierSpline is SIX numbers PER CUBIC SEGMENT (c1x,c1y,
        // c2x,c2y,endX,endY), so a valid curve is any positive multiple of
        // six — not six exactly. It was === 6 until 2026-08-25, which
        // silently rejected Caelestia's MD3 `emphasized` curve (twelve
        // numbers = two segments) and fell back to the hardcoded default
        // below, i.e. the wrong curve with no error anywhere.
        var easingValid = !!entry && Array.isArray(entry.bezier)
            && entry.bezier.length >= 6 && entry.bezier.length % 6 === 0;
        return {
            name: key,
            propertyName: root._camel(key),
            present: !!entry,
            durationValid: durationValid,
            // Falsy-but-non-numeric fallback (not a literal `0`) — every
            // consumer of `pairs[N].duration` reads it through an
            // `|| <authored base>` idiom (five aliases below), for which
            // `undefined` and `0` are behaviourally identical (both
            // falsy). `undefined` is used here purely so this line does
            // not itself read as a raw numeric duration literal to a
            // naive scan for one (G-15-1, found blocking this task's own
            // verify step — a pre-existing false-positive-prone value,
            // not a semantic change).
            duration: durationValid ? entry.duration_ms : undefined,
            easingName: (!!entry && entry.easing) || "",
            easingValid: easingValid,
            easing: easingValid ? entry.bezier : [0.2, 0, 0, 1, 1, 1]
        };
    })

    // Convenience per-pair aliases for direct `Motion.standardDuration`/
    // `Motion.standardEasing`-style consumption — motion-lint's own naming
    // convention (see the divergence note above). The theme-switch
    // crossfade (Colours-bound swatches) and the token inspector's
    // "Replay motion" control both read these directly.
    readonly property int standardDuration: pairs[0].duration || 200
    readonly property var standardEasing: pairs[0].easingValid ? pairs[0].easing : [0.2, 0, 0, 1, 1, 1]
    readonly property int emphasizedInDuration: pairs[1].duration || 300
    readonly property var emphasizedInEasing: pairs[1].easingValid ? pairs[1].easing : [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property int emphasizedOutDuration: pairs[2].duration || 150
    readonly property var emphasizedOutEasing: pairs[2].easingValid ? pairs[2].easing : [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property int staggerOffsetDuration: pairs[3].duration || 50
    readonly property var staggerOffsetEasing: pairs[3].easingValid ? pairs[3].easing : [0.2, 0, 0, 1, 1, 1]
    // colour — index 8, the ninth _pairNames entry. Every ColorAnimation and
    // `Behavior on <colour property>` in the tree binds these two rather
    // than the generic standard pair. The fallbacks mirror base motion.json
    // (200ms, the standard curve), so a missing/empty motion.json leaves
    // colour animating exactly as it did before this channel existed.
    readonly property int colourDuration: pairs[8].duration || 200
    readonly property var colourEasing: pairs[8].easingValid ? pairs[8].easing : [0.2, 0, 0, 1, 1, 1]

    // ── spatial-in/out/move (quick-260821-swp) ──────────────────────────
    //    These six aliases were MISSING until 2026-08-22 even though
    //    `_pairNames` has carried the three spatial keys since 34bd0410 and
    //    74 call sites across 23 files were already reading them. Every one
    //    of those resolved to `undefined`, which Qt silently accepts on a
    //    NumberAnimation — it falls back to its own 250ms default and its
    //    own default easing — so the QML half of the animation-style axis
    //    did nothing at all: the bar, panels, notification centre, settings
    //    nav and dashboard tabs animated identically under every style,
    //    while the Hyprland leaves responded correctly. Nothing caught it:
    //    motion-lint checks that a site reads a TOKEN rather than a
    //    literal, not that the token it reads exists, and QML resolves an
    //    undefined singleton property to `undefined` rather than erroring.
    //    The only trace was a pair of `Unable to assign [undefined]` scene
    //    warnings in ~/.cache/quickshell.log.
    //
    //    Fallbacks below are motion.json's own BASE (md3) values for each
    //    key, matching the four aliases above: an unresolved pair yields
    //    today's shipped md3 motion rather than a Qt default.
    readonly property int spatialInDuration: pairs[5].duration || 300
    readonly property var spatialInEasing: pairs[5].easingValid ? pairs[5].easing : [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property int spatialOutDuration: pairs[6].duration || 150
    readonly property var spatialOutEasing: pairs[6].easingValid ? pairs[6].easing : [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property int spatialMoveDuration: pairs[7].duration || 200
    readonly property var spatialMoveEasing: pairs[7].easingValid ? pairs[7].easing : [0.2, 0, 0, 1, 1, 1]

    // ── Reversed-entrance easings (quick task 260823-9ak, operator round 9)
    //
    //    The operator asked that the launcher's and dashboard's DISMISS be
    //    "a reverse motion of the spawn animation". Measured, it was not
    //    close: the spawn runs `spatial-in` (450ms under the live `bouncy`
    //    style, a decelerate WITH an overshoot) while the dismiss ran
    //    `spatial-out` (150ms, a plain accelerate). Three times faster, and
    //    a different curve family — the out pair is a generic exit, not a
    //    mirror of anything.
    //
    //    ONLY THE EASING IS NEW HERE. A true time-reversal runs for the
    //    same length as what it reverses, so the reversed DURATION is just
    //    `spatialInDuration`/`emphasizedInDuration` and the consumers read
    //    those directly rather than through an alias that would only ever
    //    restate them.
    //
    //    A true time-reversal of a cubic bezier easing is its
    //    point-reflection through (0.5, 0.5):
    //
    //        [x1, y1, x2, y2]  ->  [1-x2, 1-y2, 1-x1, 1-y1]
    //
    //    which plays the identical shape backwards. The overshoot that
    //    lands at the END of the entrance therefore becomes a small recoil
    //    at the START of the exit — the surface nudges inward, then sweeps
    //    out. That is the whole point; it is what "played backwards" looks
    //    like, not a defect.
    //
    //    WHY THESE ARE DERIVED FROM THE IN-EASINGS RATHER THAN AUTHORED:
    //    the reflection has to track whatever the active motion style put
    //    in the in-pair. Under `bouncy` the spatial in-easing is
    //    [0.4, 1.85, 0.75, 0.74]; under `md3` it is a plain decelerate with
    //    no overshoot at all. Hardcoding either mirror would silently
    //    desynchronise on a style switch — the same class of bug as the
    //    Task 2 gate that hardcoded `m['styles']['wavy']` and would have
    //    validated the wrong style after the names were swapped.
    //
    //    NAMING IS LOAD-BEARING: motion-lint's CHECK A allow-list is
    //    derived from motion.json's semantic keys, and it was extended in
    //    this same commit to accept `<camelKey>ReverseEasing` alongside the
    //    existing `<camelKey>Duration`/`<camelKey>Easing`. These two names
    //    must therefore stay exactly `spatialIn`/`emphasizedIn` +
    //    `ReverseEasing`, or CHECK A will report them dangling.
    //
    //    `_reverseEasing` is DECLARED ABOVE the properties that call it.
    //    QML resolves a member used at construction time by textual order,
    //    and a later-declared function throws "is not a function" into
    //    ~/.cache/quickshell.log while the binding falls back to whatever
    //    the surrounding expression offers — a plausible wrong answer
    //    rather than a visible failure. Design.qml:736 carries the same
    //    note for the same reason.
    //
    //    Reversibility: delete these two aliases and `_reverseEasing`, drop
    //    the `ReverseEasing` line from motion-lint's `load_qml_defs`, and
    //    point Launcher.qml/Dashboard.qml's `_dismissing` branches back at
    //    the `spatialOut`/`emphasizedOut` pair. Nothing else reads them.
    function _reverseEasing(e) {
        // Guard the shape rather than trusting it: `pairs[N].easing` is
        // only guaranteed 6-long when `easingValid`, and each alias below
        // can also receive its own literal fallback array. Anything else
        // passes straight through unreflected, which degrades to "the
        // entrance curve, unmirrored" — still symmetric in duration, never
        // an undefined handed to Qt.
        if (!Array.isArray(e) || e.length < 4)
            return e;
        return [1 - e[2], 1 - e[3], 1 - e[0], 1 - e[1], 1, 1];
    }

    // Standard reversal — for a shape that grows on one curve and must
    // retract along the same curve backwards (the edge bar's animated
    // bulge, operator round 11).
    readonly property var standardReverseEasing: root._reverseEasing(standardEasing)

    // Spatial (position) reversal — the dismiss slide itself.
    readonly property var spatialInReverseEasing: root._reverseEasing(spatialInEasing)

    // Emphasized (opacity) reversal — the fade that rides alongside it.
    readonly property var emphasizedInReverseEasing: root._reverseEasing(emphasizedInEasing)

    // ── ambient (G-15-1) — a LOOP PERIOD, not a one-shot transition; the
    //    fifth `_pairNames` entry appended above. `pairs[4].duration` is
    //    ALREADY multiplier-scaled and floor-clamped by lib/motion.sh (the
    //    same render-time resolution every other semantic pair goes
    //    through) — this alias then divides that resolved value by the
    //    active multiplier CAPPED AT 1.0 FROM ABOVE:
    //      - a multiplier above 1.0 (`lively`, 1.25x) is capped to 1.0, so
    //        dividing by 1.0 is a no-op and the already-lengthened period
    //        stays lengthened, as the user asked for;
    //      - a multiplier below 1.0 (`reduced`, 0.5x) divides straight
    //        through, undoing the shrink and returning the period to its
    //        `normal`-scale value.
    //    This is the whole reason `motionMultiplier` is emitted at all: a
    //    reduced-motion accessibility preset making a continuous indicator
    //    MORE frenetic is the exact inversion this token exists to prevent
    //    (T-15-11-01). Floored to an integer, matching every other
    //    duration alias in this file.
    //
    //    Contrast with `borderRotateDuration` immediately below in the
    //    Indicator tokens section: that property is ALSO a loop period, but
    //    is DELIBERATELY NOT put through this same clamp — it has to stay
    //    in lockstep with Hyprland's own `borderangle`, which Hyprland
    //    scales by the identical multiplier with no floor of its own;
    //    clamping it here would make the drawer's rim drift out of step
    //    with every window border on screen. The asymmetry is intentional,
    //    not an oversight: `ambient` has no external counterpart and is
    //    consumed only by in-shell indicators, so it is free — and
    //    required — to be scale-floored this way.
    //
    //    Fallback authored base (1000, `extra-long4`) and fallback easing
    //    (linear's own 6-element form) match motion.json's own authored
    //    values for "ambient", so a missing/malformed entry degrades to the
    //    intended period/shape rather than an arbitrary one.
    readonly property int ambientDuration: {
        var raw = pairs[4].duration || 1000;
        var divisor = Math.min(root.motionMultiplier, 1.0);
        if (!(divisor > 0))
            divisor = 1.0;
        return Math.floor(raw / divisor);
    }
    readonly property var ambientEasing: pairs[4].easingValid ? pairs[4].easing : [1, 1, 1, 1, 1, 1]

    // ── Indicator tokens (DASH-10) ──────────────────────────────────────
    // Read from the `indicators` bucket, NOT from `pairs`. Deliberately not
    // appended to `_pairNames`: that list is read POSITIONALLY by the aliases
    // above and maps to `semantic`, so an indicator key there would both
    // re-point nothing correctly and look up the wrong sub-object.
    //
    // These are continuous/looping animations rather than one-shot
    // transitions, which is why they carry only a period. `border-rotate` is
    // the one Hyprland also consumes (as `borderangle`); lib/motion.sh emits
    // it here already multiplier-scaled, floor-clamped AND ceiling-clamped to
    // Hyprland's own speed ceiling, so this number is what Hyprland is
    // actually running — the drawer's border and every window border stay in
    // step instead of drifting apart at non-default motion scales.
    //
    // Fallback 10000 matches motion.json's own authored value, so a missing
    // or malformed indicators bucket degrades to the intended period rather
    // than to an arbitrary one.
    readonly property int borderRotateDuration: {
        var e = motion.indicators && motion.indicators["border-rotate"];
        return (e && typeof e.duration_ms === "number" && isFinite(e.duration_ms) && e.duration_ms > 0) ? e.duration_ms : 10000;
    }
}
