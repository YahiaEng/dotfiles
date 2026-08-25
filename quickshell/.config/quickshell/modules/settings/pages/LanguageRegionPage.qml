// modules/settings/pages/LanguageRegionPage.qml — page index 13 (quick
// task 260825-wj2 Task 6). The three unit pickers stay `SelectRow`
// deliberately (D-9): celsius/fahrenheit and metric/imperial are
// enumerations, exactly what the reference reserves `SelectRow` for —
// poll intervals (ServicesPage.qml) are the continuous values that get
// `StepperRow` instead.
//
// Weather location — automatic/manual (quick-260826-1n9 Task 7, F6, D-8).
// The prior task's read-only decision is REVERSED here: `state.city` never
// moved the forecast (WeatherBackend.qml:418 built the request from
// `lat`/`lon` only), so a typed city that changed nothing would be exactly
// the "knob that visibly does nothing" pattern this window's InfoRow-for-
// a-non-delivery convention exists to avoid. `weatherStateFile` stays a
// READER, not a second writer — the whole point of routing the manual
// path through Prefs is that `weather.json` keeps exactly one writer
// (WeatherBackend's own watched FileView).
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Language & region"

    readonly property var _unitsModel: [
        {
            value: "auto",
            display: "Automatic"
        },
        {
            value: "metric",
            display: "Metric"
        },
        {
            value: "imperial",
            display: "Imperial"
        }
    ]

    readonly property var _weatherModeModel: [
        {
            value: "auto",
            display: "Automatic"
        },
        {
            value: "manual",
            display: "Manual"
        }
    ]

    // Snapshot taken at the moment of the last commit, so this page can
    // tell "resolving" from "resolved" WITHOUT a live link to
    // WeatherBackend (the settings window has none — that instance is
    // mounted once at shell.qml root, never relayed through SettingsState
    // the way audioBackend/wifiBackend are). Prefs is the only channel
    // BOTH sides share: WeatherBackend's own `onLocated` handler writes
    // `region.weatherLat`/`Lon` through `Prefs.setValue()`, and this page
    // reads them back through the SAME singleton. Comparing against a
    // snapshot — not against a fixed sentinel like 0 — is deliberate: 0 is
    // a real latitude, so "did the value change since I committed" is the
    // only safe test.
    property string _pendingCity: ""
    property real _pendingLatSnapshot: 0
    property real _pendingLonSnapshot: 0
    readonly property bool _resolvedSinceCommit: root._pendingCity !== "" && (Prefs.getValue("region.weatherLat") !== root._pendingLatSnapshot || Prefs.getValue("region.weatherLon") !== root._pendingLonSnapshot)

    readonly property string _weatherCitySubtext: {
        if (Prefs.getValue("region.weatherMode") !== "manual")
            return "Locked — switch to Manual to set a city.";
        if (root._pendingCity !== "" && !root._resolvedSinceCommit)
            return "Resolving…";
        var city = Prefs.getValue("region.weatherCity");
        if (city.length === 0)
            return "Type a city and press Enter.";
        var lat = Prefs.getValue("region.weatherLat");
        var lon = Prefs.getValue("region.weatherLon");
        return "Resolved to " + lat.toFixed(4) + ", " + lon.toFixed(4);
    }

    // The EFFECTIVE location and where it came from — never tells the
    // user to hand-edit weather.json any more (that file stays
    // hand-editable and authoritative in AUTOMATIC mode, and this says so
    // plainly rather than dropping the mention).
    readonly property string _effectiveLocationSubtext: {
        if (Prefs.getValue("region.weatherMode") === "manual") {
            var city = Prefs.getValue("region.weatherCity");
            if (city.length > 0) {
                var lat = Prefs.getValue("region.weatherLat");
                var lon = Prefs.getValue("region.weatherLon");
                return "Manual: " + city + " (" + lat.toFixed(4) + ", " + lon.toFixed(4) + ").";
            }
            return "Manual mode is on, but no city has been set yet — type one below.";
        }
        return (regionSection.weatherCityOverride.length > 0 ? ("weather.json sets a hand-edited city: " + regionSection.weatherCityOverride + ".") : "Automatic, based on your timezone.") + " weather.json stays hand-editable and authoritative in Automatic mode.";
    }

    SettingsSection {
        id: regionSection
        title: "Region"
        icon: "globe"

        InfoRow {
            label: "UI language"
            subtext: "This shell ships no translation layer — there is nothing to switch."
        }

        // Read-only reader on weather.json (unchanged reader shape,
        // quick task 260825-wj2 Task 6) — reports what it holds in
        // AUTOMATIC mode. Never a second writer: WeatherBackend's own
        // watched FileView is the one and only writer of this file.
        FileView {
            id: weatherStateFile
            path: Quickshell.env("HOME") + "/.local/state/theme/weather.json"
            watchChanges: true
            onFileChanged: reload()
        }
        readonly property string weatherCityOverride: {
            try {
                var obj = JSON.parse(weatherStateFile.text() || "{}");
                return (obj && typeof obj.city === "string") ? obj.city.trim() : "";
            } catch (e) {
                return "";
            }
        }

        SelectRow {
            label: "Weather location mode"
            icon: "cloud"
            subtext: "Automatic follows your timezone (or a hand-edited weather.json); Manual sets a city below"
            model: root._weatherModeModel
            currentValue: Prefs.getValue("region.weatherMode")
            onSelected: (value) => Prefs.setValue("region.weatherMode", value)
        }
        TextRow {
            label: "Weather city"
            editable: Prefs.getValue("region.weatherMode") === "manual"
            text: Prefs.getValue("region.weatherCity")
            placeholder: "e.g. Alexandria"
            subtext: root._weatherCitySubtext
            onCommitted: (v) => {
                root._pendingCity = v;
                root._pendingLatSnapshot = Prefs.getValue("region.weatherLat");
                root._pendingLonSnapshot = Prefs.getValue("region.weatherLon");
                Prefs.setValue("region.weatherCity", v);
            }
        }
        InfoRow {
            label: "Weather location"
            icon: "place"
            subtext: root._effectiveLocationSubtext
        }

        SelectRow {
            label: "Temperature units"
            subtext: "Celsius/Fahrenheit for the weather forecast"
            model: root._unitsModel
            currentValue: Prefs.getValue("region.unitsTemp")
            onSelected: (value) => Prefs.setValue("region.unitsTemp", value)
        }
        SelectRow {
            label: "Wind speed units"
            subtext: "km/h or mph for the weather forecast"
            model: root._unitsModel
            currentValue: Prefs.getValue("region.unitsWind")
            onSelected: (value) => Prefs.setValue("region.unitsWind", value)
        }
        SelectRow {
            label: "Precipitation units"
            subtext: "mm or inches for the weather forecast"
            model: root._unitsModel
            currentValue: Prefs.getValue("region.unitsPrecip")
            onSelected: (value) => Prefs.setValue("region.unitsPrecip", value)
        }
    }
}
