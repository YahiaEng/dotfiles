// Colours.qml — Quickshell.Singleton exposing the live Material You palette
// (D-11, TOKEN-01). No `pragma Singleton` and no extra qmldir markup is
// needed: Quickshell's own `Singleton` root type is exported as
// `Quickshell/Singleton 0.0` by the installed qmltypes (12-RESEARCH.md
// Pattern 2, [VERIFIED]) and already does the work.
//
// Read-only consumer of matugen's `[templates.qml]` render target
// (~/.local/state/theme/palette.json, contract.json-listed, format "json").
// commit.sh's atomic rsync is the SOLE writer of $STATE_DIR — this file
// deliberately omits `onAdapterUpdated: writeAdapter()` so it can never
// become a second writer (T-12-21 mitigation). Probe.qml's own
// FileView/JsonAdapter, on its own separate `~/.local/state/quickshell/`
// path, is unrelated and keeps its write-back for its own instrument.
//
// Fallback contract (D-11/UI-SPEC "Color" section, ui:empty|error|partial
// E1): every property below defaults to debug magenta (#FF00FF) — never a
// silent black/white default. A missing key stays at its declared default
// because JsonAdapter only overwrites a property when the matching JSON key
// is present with a compatible type; a key absent from a truncated or
// mid-render read simply never overwrites its property, so the last-good
// (or, before any successful parse, the declared magenta) value holds.
// Malformed JSON content is the same story one level up: FileView's
// `loadFailed` signal only carries FILE-level errors (not found/permission/
// not-a-file — verified against the installed
// Quickshell.Io/quickshell-io.qmltypes; there is no "invalid JSON" enum
// value), so a syntactically-broken file is diagnosed by an explicit
// `printErrors: true` + `onLoadFailed` branch below rather than left to
// implicit adapter behaviour — inspectable in source, per the plan's own
// instruction, even though the actual per-key value recovery is the same
// "never overwritten" mechanism as the missing-key case above. Both paths
// were proven live against this palette.json during this plan's Task 1
// verification (see 12-06-SUMMARY.md).
//
// D-18: no quickshell step exists anywhere in theme-apply's reload fan-out
// (grep lib/reload.sh — zero hits), and none should ever be added here for
// symmetry with the other nine themed surfaces. This singleton's
// FileView/JsonAdapter already re-colours the live surface by updating its
// properties IN PLACE; a reload would rebuild the PanelWindow and destroy
// the crossfade D-11 was chosen to enable.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Set false only on a FILE-level load failure (see loadFailed above) —
    // an explicit, inspectable flag rather than relying purely on
    // JsonAdapter's implicit per-key fallback. Not currently surfaced in
    // the UI beyond the magenta/(unmapped) captions themselves, which are
    // sufficient per D-11's "loud, not silent" requirement; kept here for
    // diagnosability (e.g. a future log line) without another plan needing
    // to touch this file to add it.
    property bool loadHealthy: true

    readonly property FileView paletteFile: FileView {
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
            id: palette
            property string primary: "#FF00FF"
            property string onPrimary: "#FF00FF"
            property string primaryContainer: "#FF00FF"
            property string onPrimaryContainer: "#FF00FF"
            property string secondary: "#FF00FF"
            property string onSecondary: "#FF00FF"
            property string secondaryContainer: "#FF00FF"
            property string onSecondaryContainer: "#FF00FF"
            property string tertiary: "#FF00FF"
            property string onTertiary: "#FF00FF"
            property string surface: "#FF00FF"
            property string onSurface: "#FF00FF"
            property string surfaceVariant: "#FF00FF"
            property string onSurfaceVariant: "#FF00FF"
            property string background: "#FF00FF"
            property string onBackground: "#FF00FF"
            property string outline: "#FF00FF"
            property string error: "#FF00FF"
            property string onError: "#FF00FF"
        }
    }

    // One readonly alias per role (D-11's 19-key QML palette contract) so
    // consumers write `Colours.primary` — never reach into `palette`
    // directly.
    readonly property alias primary: palette.primary
    readonly property alias onPrimary: palette.onPrimary
    readonly property alias primaryContainer: palette.primaryContainer
    readonly property alias onPrimaryContainer: palette.onPrimaryContainer
    readonly property alias secondary: palette.secondary
    readonly property alias onSecondary: palette.onSecondary
    readonly property alias secondaryContainer: palette.secondaryContainer
    readonly property alias onSecondaryContainer: palette.onSecondaryContainer
    readonly property alias tertiary: palette.tertiary
    readonly property alias onTertiary: palette.onTertiary
    readonly property alias surface: palette.surface
    readonly property alias onSurface: palette.onSurface
    readonly property alias surfaceVariant: palette.surfaceVariant
    readonly property alias onSurfaceVariant: palette.onSurfaceVariant
    readonly property alias background: palette.background
    readonly property alias onBackground: palette.onBackground
    readonly property alias outline: palette.outline
    readonly property alias error: palette.error
    readonly property alias onError: palette.onError

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
        { name: "surface", hex: surface },
        { name: "onSurface", hex: onSurface },
        { name: "surfaceVariant", hex: surfaceVariant },
        { name: "onSurfaceVariant", hex: onSurfaceVariant },
        { name: "background", hex: background },
        { name: "onBackground", hex: onBackground },
        { name: "outline", hex: outline },
        { name: "error", hex: error },
        { name: "onError", hex: onError }
    ]
}
