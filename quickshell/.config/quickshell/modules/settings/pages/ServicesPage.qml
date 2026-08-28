// modules/settings/pages/ServicesPage.qml — page index 12 (quick task
// 260825-wj2 Task 6, D-9). Four StepperRows (Task 5's primitive) —
// matching the reference one-for-one: `ServicesPage.qml` uses `StepperRow`
// for every polling value and reserves `SelectRow` for genuine
// pick-from-a-list choices, and a poll interval is a continuous numeric
// value with an increment, not a fixed-menu choice.
//
// The unit conversion happens at THIS row, never at any consumer site —
// each Prefs value stays in the unit its consumer already reads
// (WeatherBackend/SystemCapsule in ms, NewsBackend/SystemResources in
// their own native units), so no backend site needs a second conversion.
// `StepperRow.moved` carries a `real`; every int key is written through
// `Math.round(...)`, never the raw signal value (`Prefs.setValue`'s own
// `typeof` guard would otherwise refuse a non-integer real written where
// an int default lives).
import QtQuick
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Services"

    SettingsSection {
        title: "Polling"
        icon: "build"

        StepperRow {
            label: "Weather refresh"
            subtext: "How often the weather forecast refreshes (minutes)"
            from: 5
            to: 120
            stepSize: 5
            value: Prefs.getValue("services.weatherRefreshMs") / 60000
            onMoved: (v) => Prefs.setValue("services.weatherRefreshMs", Math.round(v) * 60000)
        }
        StepperRow {
            label: "News cache lifetime"
            subtext: Prefs.getValue("services.newsTtlMinutes") === 0
                ? "0 = follow news-sources.json's own ttl_minutes"
                : "How long fetched news stays cached before refetching (minutes)"
            from: 0
            to: 1440
            stepSize: 5
            value: Prefs.getValue("services.newsTtlMinutes")
            onMoved: (v) => Prefs.setValue("services.newsTtlMinutes", Math.round(v))
        }
        StepperRow {
            label: "System stats refresh"
            subtext: "CPU, memory and GPU update interval (seconds)"
            from: 1
            to: 10
            stepSize: 1
            value: Prefs.getValue("services.resourcesPollMs") / 1000
            onMoved: (v) => Prefs.setValue("services.resourcesPollMs", Math.round(v) * 1000)
        }
        // "Update check" MOVED to Settings > Packages (quick task
        // 260828-75k). It sets services.updatesPollMs, which is still the
        // one key — the row moved to sit beside the rest of the package
        // settings rather than being duplicated in two pages.
    }
}
