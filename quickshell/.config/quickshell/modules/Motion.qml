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
    readonly property var _pairNames: ["standard", "emphasized-in", "emphasized-out", "stagger-offset"]

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
            // These two MUST carry motion.json's own snake_case key names.
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
            property bool motion_enabled: true
            property string motion_scale: "normal"
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
    readonly property alias motionScale: motion.motion_scale

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
        var easingValid = !!entry && Array.isArray(entry.bezier) && entry.bezier.length === 6;
        return {
            name: key,
            propertyName: root._camel(key),
            present: !!entry,
            durationValid: durationValid,
            duration: durationValid ? entry.duration_ms : 0,
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
