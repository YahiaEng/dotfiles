// Colours.qml — Quickshell.Singleton exposing the live Material You palette
// (D-11, TOKEN-01).
//
// pragma Singleton + qmldir's `singleton` keyword ARE both required — this
// corrects 12-RESEARCH.md Pattern 2's claim that neither is needed. Binary
// verification (this plan, Task 1, standing constraint 2) found the
// opposite: WITHOUT the qmldir `singleton` keyword, `Colours.primary`-style
// bare-type-name property access resolves to `undefined` FOREVER — the
// object is never even constructed (proven with a `Component.onCompleted`
// that never fires and a repeating Timer that never sees a value change).
// `Quickshell/Singleton 0.0`'s export only affects RELOAD PROPAGATION
// behaviour, not classic QML singleton addressing.
//
// SECOND finding, also binary-verified this plan: a `pragma Singleton`
// QML type CANNOT declare a property named "X" and a property named "onX"
// (Material You's own `role`/`onRole` naming convention) in the SAME
// object — Qt's singleton AOT compiler misparses the "onX" declaration as
// a signal-handler binding for a same-named signal and fails with "Cannot
// assign a value to a signal (expecting a script to be run)", even though
// it is written as an ordinary `property string onX: ...` declaration.
// Reproduced with a minimal 2-property QtObject (`primary` + `onPrimary`
// alone, nothing else) — this is a genuine compiler limitation, not a
// mistake in this file's syntax. Fix: split into two sibling
// FileView/JsonAdapter pairs — `base` (role names) and `onRoles` (paired
// "on"-role names) — so no single object ever holds both members of an
// X/onX pair; the outer Singleton's `readonly property alias` layer (which
// DOES hold both on the same object) is unaffected, proven safe in the
// same verification pass.
//
// Read-only consumer of matugen's `[templates.qml]` render target
// (~/.local/state/theme/palette.json, contract.json-listed, format "json").
// commit.sh's atomic rsync is the SOLE writer of $STATE_DIR — this file
// deliberately omits `onAdapterUpdated: writeAdapter()` on both FileViews
// so it can never become a second writer (T-12-21 mitigation). Probe.qml's
// own FileView/JsonAdapter, on its own separate
// `~/.local/state/quickshell/` path, is unrelated and keeps its write-back
// for its own instrument.
//
// Fallback contract (D-11/UI-SPEC "Color" section, ui:empty|error|partial
// E1): every property below defaults to debug magenta (#FF00FF) — never a
// silent black/white default. A missing key stays at its declared default
// because JsonAdapter only overwrites a property when the matching JSON key
// is present with a compatible type. Malformed JSON content takes the same
// path: FileView's `loadFailed` signal only carries FILE-level errors (not
// found/permission/not-a-file — verified against the installed
// Quickshell.Io/quickshell-io.qmltypes; there is no "invalid JSON" enum
// value), so a syntactically-broken file is diagnosed by an explicit
// `printErrors: true` + `onLoadFailed` branch on both FileViews below
// rather than left to implicit adapter behaviour — inspectable in source.
// Empirically observed live (this plan's Task 1 verification, see
// 12-06-SUMMARY.md): on the FIRST read before palette.json has loaded, a
// bound consumer briefly sees the declared magenta default, then the real
// value the instant the async read completes — a one-frame fallback flash,
// not a bug, and the direct answer to 12-UI-SPEC.md's RESEARCH carry-over
// question about matugen's write atomicity (moot: this flash is about the
// FIRST-EVER read racing FileView's own async load, not about matugen's
// write mechanism, which commit.sh's atomic rsync already makes moot for
// every read after the first).
//
// D-18: no quickshell step exists anywhere in theme-apply's reload fan-out
// (grep lib/reload.sh — zero hits), and none should ever be added here for
// symmetry with the other nine themed surfaces. This singleton's
// FileViews/JsonAdapters already re-colour the live surface by updating
// their properties IN PLACE; a reload would rebuild the PanelWindow and
// destroy the crossfade D-11 was chosen to enable.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Set false only on a FILE-level load failure (see loadFailed below) —
    // an explicit, inspectable flag rather than relying purely on
    // JsonAdapter's implicit per-key fallback. Not currently surfaced in
    // the UI beyond the magenta/(unmapped) captions themselves, which are
    // sufficient per D-11's "loud, not silent" requirement; kept here for
    // diagnosability (e.g. a future log line) without another plan needing
    // to touch this file to add it.
    property bool loadHealthy: true

    // ── "base" role names — never "on"-prefixed, so this object can never
    //    collide with the compiler bug described above. ──────────────────
    FileView {
        id: baseFile
        path: Quickshell.env("HOME") + "/.local/state/theme/palette.json"
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
            id: base
            property string primary: "#FF00FF"
            property string primaryContainer: "#FF00FF"
            property string secondary: "#FF00FF"
            property string secondaryContainer: "#FF00FF"
            property string tertiary: "#FF00FF"
            property string tertiaryContainer: "#FF00FF"
            property string surface: "#FF00FF"
            property string surfaceVariant: "#FF00FF"
            // ROLE-01: the M3 tonal-surface ladder. Emitted for BOTH branches
            // — matugen computes it natively for the wallpaper branch, and
            // lib/generate.sh derives it for static presets before matugen
            // sees them, so the two modes carry an identical role set.
            property string surfaceContainerLowest: "#FF00FF"
            property string surfaceContainerLow: "#FF00FF"
            property string surfaceContainer: "#FF00FF"
            property string surfaceContainerHigh: "#FF00FF"
            property string surfaceContainerHighest: "#FF00FF"
            property string surfaceDim: "#FF00FF"
            property string surfaceBright: "#FF00FF"
            property string background: "#FF00FF"
            property string outline: "#FF00FF"
            property string outlineVariant: "#FF00FF"
            property string error: "#FF00FF"
            property string errorContainer: "#FF00FF"
            property string scrim: "#FF00FF"
            property string shadow: "#FF00FF"
        }
    }

    // ── "on" role names — a SEPARATE FileView/JsonAdapter pair reading the
    //    SAME palette.json path, so no object ever holds both a role and
    //    its "on"-paired counterpart. ────────────────────────────────────
    FileView {
        id: onFile
        path: Quickshell.env("HOME") + "/.local/state/theme/palette.json"
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
            id: onRoles
            property string onPrimary: "#FF00FF"
            property string onPrimaryContainer: "#FF00FF"
            property string onSecondary: "#FF00FF"
            property string onSecondaryContainer: "#FF00FF"
            property string onTertiary: "#FF00FF"
            property string onTertiaryContainer: "#FF00FF"
            property string onSurface: "#FF00FF"
            property string onSurfaceVariant: "#FF00FF"
            property string onBackground: "#FF00FF"
            property string onError: "#FF00FF"
            property string onErrorContainer: "#FF00FF"
        }
    }

    // One readonly alias per role (D-11's QML palette contract, grown from 19
    // to 33 keys by quick task 260828-u0r) so
    // consumers write `Colours.primary` — never reach into `base`/`onRoles`
    // directly. Both an X and its onX alias coexist here safely (verified):
    // the compiler bug above is specific to the underlying STORAGE object,
    // not to this alias layer.
    readonly property alias primary: base.primary
    readonly property alias onPrimary: onRoles.onPrimary
    readonly property alias primaryContainer: base.primaryContainer
    readonly property alias onPrimaryContainer: onRoles.onPrimaryContainer
    readonly property alias secondary: base.secondary
    readonly property alias onSecondary: onRoles.onSecondary
    readonly property alias secondaryContainer: base.secondaryContainer
    readonly property alias onSecondaryContainer: onRoles.onSecondaryContainer
    readonly property alias tertiary: base.tertiary
    readonly property alias onTertiary: onRoles.onTertiary
    readonly property alias tertiaryContainer: base.tertiaryContainer
    readonly property alias onTertiaryContainer: onRoles.onTertiaryContainer
    readonly property alias surface: base.surface
    readonly property alias onSurface: onRoles.onSurface
    readonly property alias surfaceVariant: base.surfaceVariant
    readonly property alias onSurfaceVariant: onRoles.onSurfaceVariant
    readonly property alias surfaceContainerLowest: base.surfaceContainerLowest
    readonly property alias surfaceContainerLow: base.surfaceContainerLow
    readonly property alias surfaceContainer: base.surfaceContainer
    readonly property alias surfaceContainerHigh: base.surfaceContainerHigh
    readonly property alias surfaceContainerHighest: base.surfaceContainerHighest
    readonly property alias surfaceDim: base.surfaceDim
    readonly property alias surfaceBright: base.surfaceBright
    readonly property alias background: base.background
    readonly property alias onBackground: onRoles.onBackground
    readonly property alias outline: base.outline
    readonly property alias outlineVariant: base.outlineVariant
    readonly property alias error: base.error
    readonly property alias onError: onRoles.onError
    readonly property alias errorContainer: base.errorContainer
    readonly property alias onErrorContainer: onRoles.onErrorContainer
    readonly property alias scrim: base.scrim
    readonly property alias shadow: base.shadow

    // Ordered {name, hex} list for the token inspector's swatch repeater
    // (D-15) — the ONE definition of "every colour role", never
    // hand-duplicated as a second list inside Probe.qml. Growing/renaming a
    // role only ever means touching this file.
    readonly property var roles: [
        { name: "primary", hex: primary },
        { name: "onPrimary", hex: onPrimary },
        { name: "primaryContainer", hex: primaryContainer },
        { name: "onPrimaryContainer", hex: onPrimaryContainer },
        { name: "secondary", hex: secondary },
        { name: "onSecondary", hex: onSecondary },
        { name: "secondaryContainer", hex: secondaryContainer },
        { name: "onSecondaryContainer", hex: onSecondaryContainer },
        { name: "tertiary", hex: tertiary },
        { name: "onTertiary", hex: onTertiary },
        { name: "tertiaryContainer", hex: tertiaryContainer },
        { name: "onTertiaryContainer", hex: onTertiaryContainer },
        { name: "surface", hex: surface },
        { name: "onSurface", hex: onSurface },
        { name: "surfaceVariant", hex: surfaceVariant },
        { name: "onSurfaceVariant", hex: onSurfaceVariant },
        { name: "surfaceContainerLowest", hex: surfaceContainerLowest },
        { name: "surfaceContainerLow", hex: surfaceContainerLow },
        { name: "surfaceContainer", hex: surfaceContainer },
        { name: "surfaceContainerHigh", hex: surfaceContainerHigh },
        { name: "surfaceContainerHighest", hex: surfaceContainerHighest },
        { name: "surfaceDim", hex: surfaceDim },
        { name: "surfaceBright", hex: surfaceBright },
        { name: "background", hex: background },
        { name: "onBackground", hex: onBackground },
        { name: "outline", hex: outline },
        { name: "outlineVariant", hex: outlineVariant },
        { name: "error", hex: error },
        { name: "onError", hex: onError },
        { name: "errorContainer", hex: errorContainer },
        { name: "onErrorContainer", hex: onErrorContainer },
        { name: "scrim", hex: scrim },
        { name: "shadow", hex: shadow }
    ]
}
