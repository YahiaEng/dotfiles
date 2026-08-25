// modules/settings/pages/LanguageRegionPage.qml — page index 13 (quick
// task 260825-wj2 Task 6). "Weather location" moved verbatim from
// NotificationsPage.qml, together with its `FileView`/
// `weatherCityOverride` reader — stays read-only, since `weather.json` is
// hand-edit-only (WeatherBackend has no city writer) and adding one here
// would make this a second writer for that file. The three unit pickers
// stay `SelectRow` deliberately (D-9): celsius/fahrenheit and metric/
// imperial are enumerations, exactly what the reference reserves
// `SelectRow` for — poll intervals (ServicesPage.qml) are the continuous
// values that get `StepperRow` instead.
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

    SettingsSection {
        id: regionSection
        title: "Region"
        icon: "globe"

        InfoRow {
            label: "UI language"
            subtext: "This shell ships no translation layer — there is nothing to switch."
        }

        // Moved verbatim from NotificationsPage.qml (quick task 260825-wj2
        // Task 6) — same FileView, same reader, same honest non-delivery
        // rationale: weather.json is hand-edit-only.
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
        InfoRow {
            label: "Weather location"
            subtext: (regionSection.weatherCityOverride.length > 0
                ? ("Set to: " + regionSection.weatherCityOverride)
                : "Automatic, based on your timezone.") + " To set a specific city, edit ~/.local/state/theme/weather.json."
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
