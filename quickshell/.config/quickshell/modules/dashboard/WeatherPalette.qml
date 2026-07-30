// WeatherPalette.qml — a deliberate, documented exemption to the repo-wide
// zero-hex/duration-literal invariant's palette contract (Phase 14 Plan 09,
// Task 4 render-gate change request).
//
// ── Citation correction (Phase 14 Plan 10, Task 1) ───────────────────────
// This header and 14-09-SUMMARY.md both originally cited this exemption as
// an exemption to "D-11's palette contract". That decision number is wrong:
// in `14-CONTEXT.md`, D-11 is the DASH-08 fullscreen-refusal decision
// ("refusal is a silent no-op on TRUE fullscreen only; maximized windows do
// not block") — nothing to do with colour. The actual contract is the same
// file's repo-wide invariant line, "Zero hex/duration literals in
// repo-authored UI — everything through" the token singletons. 14-09 had
// the number wrong; this plan corrects the citation here, in the file a
// future reader will actually open, rather than only in a plan document.
// Every word of the rationale below is otherwise unchanged.
//
// ── Why this file exists ─────────────────────────────────────────────────
// The zero-hex/duration-literal invariant's contract is that every colour in
// this drawer is one of `Colours`' 19 Material You roles — a value that
// moves with the active theme, never an absolute. The Task 4 human render
// gate asked for something that
// contract cannot express: weather condition glyphs (sun, cloud, rain,
// snow, storm) and the sunrise/sunset glyphs coloured so they read apart
// from each other at a glance — "yellow sun, white sunny clouds, grey/dark
// rainy clouds". A Material You role is, by construction, whatever the
// active wallpaper/theme currently maps it to; there is no `Colours.*` role
// that is guaranteed to stay "yellow" across a theme switch, because that
// is exactly the property Colours.* is built to NOT have. Discriminability
// between eight-plus weather conditions at icon size cannot be built out of
// 19 harmonised, theme-relative roles — and unlike a container or a label,
// a weather glyph's colour genuinely IS part of its meaning: a rain cloud
// reads as rain partly *because* it is grey, in every icon language that
// exists. This is the same class of exception `Colours.error` already
// grants within the contract itself (a role that is deliberately NOT
// harmonised the same way primary/secondary/tertiary are, because a
// warning has to mean the same thing regardless of the current palette) —
// this file extends that same reasoning to a second, narrower case the
// 19-role set does not otherwise cover.
//
// ── What stays theme-owned (the scope boundary, restated) ───────────────
// Every other colour on the Weather tab — every text label, every surface,
// every container, the staleness badge, the separator line — reads
// `Colours.*` exactly as before. This file is consulted from exactly two
// places in `WeatherTab.qml`: the weather condition glyph (hero + each
// hour/day cell) and the sunrise/sunset glyphs. Nothing else in the drawer
// may import this file; a grep for it outside `WeatherTab.qml` is a
// regression.
//
// ── The 12-06 / Design.qml finding, applied here too ────────────────────
// Both `pragma Singleton` below AND the `singleton` keyword on this
// directory's `qmldir` line are required — omitting either yields a type
// that is never constructed and reads `undefined` forever with no load
// error (the finding `Design.qml` already carries verbatim).
//
// ── Provenance ────────────────────────────────────────────────────────────
// `sun`/`cloudLit`/`cloudRain`/`sunrise`/`sunset` are the five starting
// values the human approved directly at the Task 4 gate. `night`/`snow`/
// `storm` were added here to cover the rest of `WeatherBackend.qml`'s own
// `_wmoTable` ligature-name set (clear_night, partly_cloudy_night, the snow
// family, thunderstorm/hail) rather than leaving those conditions
// unmapped — tuned by direct read against a bright wallpaper (D-07); see
// 14-09-SUMMARY.md's Task 4 section for the live-legibility verdict and
// whether any value moved from what is written here.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // ── The absolute palette ─────────────────────────────────────────────
    readonly property color sun: "#FFC107"
    readonly property color night: "#90A4AE"
    readonly property color cloudLit: "#ECEFF1"
    readonly property color cloudRain: "#78909C"
    readonly property color snow: "#E1F5FE"
    readonly property color storm: "#546E7A"
    readonly property color sunrise: "#FFD54F"
    readonly property color sunset: "#7986CB"

    // ── The resolver — every ligature name `WeatherBackend.qml`'s
    //    `_wmoTable` can emit, mapped once, here, so `WeatherTab.qml` never
    //    branches on a condition name inline. Keyed by symbol name (what the
    //    tab actually has at each render site) rather than by WMO code,
    //    since the tab never sees the raw code — only `entry.symbol`. An
    //    unrecognised name (the "help" fallback `WeatherBackend.qml` itself
    //    returns for an unknown WMO code, or the "cloud_off" empty-state
    //    icon, which is not a weather condition at all) returns `null` so
    //    the caller falls back to its own themed `Colours.*` value rather
    //    than an absolute colour. ────────────────────────────────────────
    readonly property var _symbolToColor: ({
            "clear_day": root.sun,
            "clear_night": root.night,
            "partly_cloudy_day": root.cloudLit,
            "partly_cloudy_night": root.night,
            "cloud": root.cloudLit,
            "foggy": root.cloudRain,
            "rainy_light": root.cloudRain,
            "rainy": root.cloudRain,
            "rainy_heavy": root.cloudRain,
            "weather_mix": root.cloudRain,
            "weather_snowy": root.snow,
            "snowing": root.snow,
            "snowing_heavy": root.snow,
            "grain": root.snow,
            "thunderstorm": root.storm,
            "weather_hail": root.storm
        })

    function forSymbol(name) {
        return root._symbolToColor[name] || null;
    }
}
