// WeatherBackend.qml — inert shell-root backend stub (Phase 14 Plan 03,
// filled by Plan 14-07, D-29..D-33).
//
// Root type `Scope` (from `Quickshell`, NOT `Item`) — verified present in
// the installed quickshell-core.qmltypes with `children` as its default
// property, which is what lets 14-07's fetch/cache `FileView`/timer be
// declared as plain children later. `Scope` renders nothing and mounts
// cleanly under `ShellRoot` with no window, unlike an `Item`.
//
// `drawerOpen` (D-32) is the lifecycle gate every wave-3 backend carries:
// the ~15-min TTL refresh timer this backend eventually owns may run only
// while this is true, bound by shell.qml to `dashboardLoader.active`
// (D-14). In stub form this backend starts no process, opens no socket,
// reads no file and runs no timer — zero idle footprint is the tracer's
// promise (14-01) and this task must not break it before the widget even
// exists.
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files, even the
// non-visual backends, so the vocabulary is uniform across the whole
// module surface.
//
// ── Filled (Phase 14 Plan 07, D-29..D-33) ───────────────────────────────
// This is the ONE place in the repository from which a weather request may
// be issued (D-29's one-file fence, COVERAGE.md's integration fence). The
// only Open-Meteo host reference under `quickshell/` lives in
// `forecastEndpoint` below.
//
// ── Design constants — none declared here ───────────────────────────────
// Read `Dashboard.qml` (14-03's as-built root) first per this task's own
// instruction: `dashboardWindow` publishes its spacing/type-scale constants
// on itself, but this file is mounted as a sibling of `dashboardLoader` in
// `shell.qml` (D-14, round-3 render-gate correction precedent already set
// by `SystemResources.qml`) — entirely outside `Dashboard.qml`'s object
// tree, not merely a separate registered component type instantiated
// inside it the way the four tabs are. A bare `dashboardWindow.spacingLg`
// reference would not resolve for the SAME lexical-scope reason MediaTab.qml
// and PerformanceTab.qml already recorded, and this file needs none of
// those constants anyway: it is non-visual (a `Scope`, never a `Text` or
// `Rectangle`), so it never sets a `font.pixelSize` or a spacing value.
// The one constant that DOES matter — the exact Material Symbols family
// string — is a rendering concern, not a data concern: this file returns
// bare ligature NAMES ("clear_day", "rainy", …) and never a `font.family`
// string itself; `WeatherTab.qml` (Task 2) is what pairs a name with the
// family. Consolidation note for 14-08, restated in the SUMMARY: no local
// design constants were needed in this file, and no cross-file constants
// contract exists between `Dashboard.qml` and either wave-3 backend.
//
// ── The request (D-29, COVERAGE.md) ─────────────────────────────────────
// One function (`buildRequestUrl`) builds one URL against `forecastEndpoint`.
// Every INTEGRATE capability COVERAGE.md names is present: the six current
// fields, the two hourly fields, the five daily fields, `timezone=auto`,
// `forecast_days` bound to `forecastDays`, and all three unit parameters
// derived from the three state-file keys (metric is the fall-through for
// any unrecognised unit string). The forecast fence still holds: this file
// is the ONE place a WEATHER request may be issued, and `forecastEndpoint`
// is the only Open-Meteo host reference under `quickshell/`. The surviving
// OPT-OUT items: no sub-hourly block, no alerts, no air quality, no
// archive, no model selection, no API key.
//
// ── CORRECTED (quick task 260818-v3m) ────────────────────────────────────
// This paragraph used to assert that no location lookup of any kind existed
// anywhere in this tree. That claim is now false, and the fix is a
// deliberate, recorded REVERSAL of the Phase-14 plan-time criterion above —
// not drift. The rule is now one host per fenced file: a reverse geocode is
// issued from `GeocodeBackend.qml`, a sibling registered in
// `modules/dashboard/qmldir`, and that file is the only place its own host
// appears — see its own header for the full privacy/rate-policy rationale.
// Geocoding is no longer among this file's OPT-OUT items; do not read it
// back into that list. The operator's coordinates now reach a SECOND host
// as a direct result of this task.
//
// ── Coordinate validation (T-14-03) ─────────────────────────────────────
// `lat`/`lon` are received as raw JSON values (`property var` inside the
// JsonAdapter below) rather than declared numeric, so a hand-edited string
// stays detectably non-numeric instead of silently coercing to zero.
// `coordsValid` requires number type, finiteness and real latitude/
// longitude ranges before anything downstream may build a URL, start a
// request or write a cache.
//
// ── Cache (D-32, T-14-02, T-14-26) ──────────────────────────────────────
// A second, unwatched `FileView` with `atomicWrites: true` on
// `weather-cache.json`, read once at construction. Every parse — the
// network response and the cache file alike — sits inside try/catch behind
// an explicit shape check; a failure leaves the last-good payload
// untouched and never half-renders the tab (14-UI-SPEC.md's partial row).
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    // D-41: "populated" | "pending" | "empty"
    property string widgetState: "empty"

    // Lifecycle gate (D-32) — bound by shell.qml to dashboardLoader.active.
    // Starts nothing while false.
    property bool drawerOpen: false

    // ── Cadence + threshold constants (D-32/D-33) — named so no timer or
    //    comparison below ever carries a bare number. None of these is a
    //    motion property: motion-lint's raw-value check is anchored on a
    //    lowercase `duration:` key and a Timer's `interval:` is structurally
    //    invisible to it (SystemResources.qml's own header note, reused
    //    verbatim here). D-32/D-33 name these as approximate starting
    //    points; naming them is what makes retuning a one-number edit. ────
    readonly property int cacheTtlMs: 15 * 60 * 1000
    readonly property int refreshIntervalMs: 15 * 60 * 1000
    readonly property int staleBadgeMs: 60 * 60 * 1000
    readonly property int staleWarnMs: 6 * 60 * 60 * 1000
    readonly property int clockIntervalMs: 60 * 1000
    readonly property int hourColumns: 8
    readonly property int forecastDays: 5

    // ── The provider seam (D-29's one-file fence made concrete) ─────────
    readonly property string forecastEndpoint: "https://api.open-meteo.com/v1/forecast"

    // ── State-file read (D-30/D-31 consumption side) ────────────────────
    // Watched FileView, Colours.qml's exact shape: watchChanges true,
    // printErrors true, reload on file change, loadHealthy tracked
    // explicitly rather than left to implicit adapter behaviour.
    property bool stateLoadHealthy: true

    // `FileView` reads are asynchronous by default — this flips true the
    // first time the state file's own load settles (success OR failure),
    // one way or the other. Load-bearing for `loadCache()`/
    // `_revalidateAgainstSettings()` below: without it, a cache-vs-settings
    // comparison made before this file has ever loaded compares against
    // `lat`/`lon`'s still-default `null`, which reads as a mismatch against
    // any real cached coordinate and spuriously invalidates a perfectly
    // good cache on every single reconstruction — a real race found live
    // while testing this task (see 14-07-SUMMARY.md).
    property bool stateFileEverLoaded: false

    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.local/state/theme/weather.json"
        watchChanges: true
        printErrors: true
        onLoaded: {
            root.stateFileEverLoaded = true;
        }
        onFileChanged: {
            root.stateLoadHealthy = true;
            reload();
        }
        onLoadFailed: (error) => {
            root.stateLoadHealthy = false;
            root.stateFileEverLoaded = true;
        }

        // 14-02's five flat top-level keys (Pitfall 5: JsonAdapter maps
        // top-level keys only). `lat`/`lon` are `var`, not `real` —
        // load-bearing (see header): a numeric declaration would silently
        // coerce a hand-edited string to 0. Units default to the metric
        // value 14-02 seeded.
        JsonAdapter {
            id: state
            property var lat: null
            property var lon: null
            property string units_temp: "metric"
            property string units_wind: "metric"
            property string units_precip: "metric"
            // Quick task 260818-v3m — OPTIONAL manual override. Hand-
            // editable only: deliberately absent from stow.sh's seed (this
            // task does not touch a contract-registered seed file). When
            // set, it wins outright over the geocode/timezone chain below
            // and NO geocode request is issued at all.
            property string city: ""
        }
    }

    readonly property alias lat: state.lat
    readonly property alias lon: state.lon
    readonly property alias unitsTemp: state.units_temp
    readonly property alias unitsWind: state.units_wind
    readonly property alias unitsPrecip: state.units_precip
    // Raw alias mirroring the pattern above exactly — this is what lets
    // `onCityChanged` below fire the same way `onLatChanged` etc. already
    // do. `cityOverride` (below) is the trimmed, public-facing value
    // everything else reads.
    readonly property alias city: state.city
    // Quick task 260818-v3m — trimmed optional override, see JsonAdapter's
    // own comment above.
    readonly property string cityOverride: String(state.city).trim()

    // ── T-14-03 mitigation: validate before constructing anything ───────
    readonly property bool coordsValid: {
        if (typeof root.lat !== "number" || typeof root.lon !== "number")
            return false;
        if (!isFinite(root.lat) || !isFinite(root.lon))
            return false;
        if (root.lat < -90 || root.lat > 90)
            return false;
        if (root.lon < -180 || root.lon > 180)
            return false;
        return true;
    }

    // Single onCoordsValidChanged handler (a second declaration would be a
    // duplicate signal handler, the same class of bug SystemResources.qml's
    // header already found and documented) — logs the invalid transition
    // AND drives the D-41 register, which is why _updateWidgetState() is
    // called from here rather than from a second handler on this signal.
    onCoordsValidChanged: {
        if (!root.coordsValid) {
            console.log("WeatherBackend: coordinates invalid (lat=" + JSON.stringify(root.lat) + ", lon=" + JSON.stringify(root.lon) + ") — no request will be issued");
        }
        root._updateWidgetState();
    }

    // Reading the state file invalidates a mismatched cache and, if the
    // drawer is open, triggers a fetch (D-30/D-31 consumption side).
    onLatChanged: root._revalidateAgainstSettings()
    onLonChanged: root._revalidateAgainstSettings()
    onUnitsTempChanged: root._revalidateAgainstSettings()
    onUnitsWindChanged: root._revalidateAgainstSettings()
    onUnitsPrecipChanged: root._revalidateAgainstSettings()
    // Quick task 260818-v3m — same pattern as the five handlers above: a
    // hand-edit to the override key routes through the single
    // _revalidateAgainstSettings() chokepoint below (which already drives
    // the geocode chain's own resolver — see its documented call sites,
    // "no third call site" by design) rather than adding a second, direct
    // call site here.
    onCityChanged: root._revalidateAgainstSettings()

    // ── Published request/response state ────────────────────────────────
    property bool requestInFlight: false
    property bool lastFetchFailed: false
    property var _currentXhr: null

    // The one payload every rendered band derives from (D-29). Never
    // cleared by a failed refresh — that is the whole mechanism behind
    // D-33's calm degradation.
    property var payload: null
    property real fetchedAtMs: 0
    property bool hasPayload: false

    // What coordinates/units `payload` was fetched under — compared against
    // the live state file so a cache/response fetched for a different
    // location or unit system is treated as absent, not merely stale.
    property real _cachedLat: NaN
    property real _cachedLon: NaN
    property string _cachedUnitsTemp: ""
    property string _cachedUnitsWind: ""
    property string _cachedUnitsPrecip: ""
    // Quick task 260818-v3m — the reverse-geocoded city, cached alongside
    // the forecast. Cleared by the SAME coordinate-change invalidation
    // that clears the payload below (_revalidateAgainstSettings()) — no
    // second coordinate-change detector.
    property string _cachedCity: ""

    // Advances only while the drawer is open (clockTimer below) — both the
    // age badge and the eight-hour window read this, never Date.now()
    // directly, so both freeze the instant the drawer closes.
    property real nowMs: Date.now()

    readonly property real ageMs: root.hasPayload ? (root.nowMs - root.fetchedAtMs) : Infinity
    readonly property bool isStale: !root.hasPayload || root.ageMs > root.cacheTtlMs

    // D-41 register, driven from the published state below. coordsValid's
    // own transition is handled by the single onCoordsValidChanged handler
    // declared above (a second one here would be a duplicate handler).
    onHasPayloadChanged: root._updateWidgetState()
    onRequestInFlightChanged: root._updateWidgetState()

    function _updateWidgetState() {
        if (!root.coordsValid) {
            root.widgetState = "empty";
        } else if (root.hasPayload) {
            root.widgetState = "populated";
        } else if (root.requestInFlight) {
            root.widgetState = "pending";
        } else {
            root.widgetState = "empty";
        }
    }

    function cacheMatchesSettings() {
        return root._cachedLat === root.lat
            && root._cachedLon === root.lon
            && root._cachedUnitsTemp === root.unitsTemp
            && root._cachedUnitsWind === root.unitsWind
            && root._cachedUnitsPrecip === root.unitsPrecip;
    }

    function _revalidateAgainstSettings() {
        // Never invalidate against a state file that hasn't loaded yet —
        // `lat`/`lon` still sitting at their declared `null` default is
        // "not yet known", not "genuinely different", and must not be
        // read as a location change (see `stateFileEverLoaded`'s header
        // note above).
        if (root.stateFileEverLoaded && root.hasPayload && !root.cacheMatchesSettings()) {
            // A cache/response fetched for a DIFFERENT location or unit
            // system is wrong, not stale — treat it as though it never
            // existed rather than showing the previous city's numbers
            // behind an age badge implying they are merely old (D-30/D-31).
            root.hasPayload = false;
            root.payload = null;
            root.fetchedAtMs = 0;
            // Quick task 260818-v3m — this IS the "once per coordinate
            // change" trigger for the geocode chain (no second detector):
            // a city resolved for DIFFERENT coordinates is wrong, not
            // stale, exactly like the payload beside it. Abort the child's
            // own outstanding request too — a stale in-flight response
            // must never resolve into the new coordinates' cached city.
            root._cachedCity = "";
            geocoder.abort();
        }
        if (root.drawerOpen)
            root.fetchIfStale();
        root._resolveCityIfNeeded();
    }

    // ── The request (D-29, COVERAGE.md) ─────────────────────────────────
    function buildRequestUrl() {
        var tempParam = root.unitsTemp === "imperial" ? "fahrenheit" : "celsius";
        var windParam = root.unitsWind === "imperial" ? "mph" : "kmh";
        var precipParam = root.unitsPrecip === "imperial" ? "inch" : "mm";
        var params = ["latitude=" + encodeURIComponent(root.lat), "longitude=" + encodeURIComponent(root.lon), "current=" + encodeURIComponent("temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day"), "hourly=" + encodeURIComponent("temperature_2m,weather_code"), "daily=" + encodeURIComponent("weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"), "timezone=auto", "forecast_days=" + root.forecastDays, "temperature_unit=" + encodeURIComponent(tempParam), "wind_speed_unit=" + encodeURIComponent(windParam), "precipitation_unit=" + encodeURIComponent(precipParam)];
        return root.forecastEndpoint + "?" + params.join("&");
    }

    // Shape check (Security V5, T-14-02) — a parsed response is not yet a
    // payload. Reused identically for the cache file below.
    function _payloadShapeValid(json) {
        if (!json || typeof json !== "object")
            return false;
        var c = json.current;
        if (!c || typeof c.temperature_2m !== "number" || !isFinite(c.temperature_2m))
            return false;
        if (typeof c.weather_code !== "number" || !Number.isInteger(c.weather_code))
            return false;
        var h = json.hourly;
        if (!h || !Array.isArray(h.time) || !Array.isArray(h.temperature_2m))
            return false;
        if (h.time.length !== h.temperature_2m.length)
            return false;
        var d = json.daily;
        if (!d || !Array.isArray(d.time) || d.time.length === 0)
            return false;
        return true;
    }

    // Refuses a second request while one is outstanding (T-14-25) and
    // fetches only when the cache is genuinely stale (D-32) — never on a
    // schedule, never on every summon.
    function fetchIfStale() {
        if (!root.drawerOpen)
            return;
        if (!root.coordsValid)
            return;
        if (root.requestInFlight)
            return;
        if (root.hasPayload && !root.isStale)
            return;

        root.requestInFlight = true;
        var url = root.buildRequestUrl();
        var xhr = new XMLHttpRequest();
        root._currentXhr = xhr;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            root.requestInFlight = false;
            root._currentXhr = null;
            if (xhr.status !== 200) {
                root.lastFetchFailed = true;
                console.log("WeatherBackend: fetch failed with status " + xhr.status);
                return;
            }
            try {
                var json = JSON.parse(xhr.responseText);
                root.applyResponse(json);
            } catch (e) {
                root.lastFetchFailed = true;
                console.log("WeatherBackend: response JSON parse failed: " + e);
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // Never clears an existing payload on failure — a failed refresh leaves
    // the last good data exactly where it was (D-33).
    function applyResponse(json) {
        if (!root._payloadShapeValid(json)) {
            root.lastFetchFailed = true;
            console.log("WeatherBackend: response failed shape check — keeping last-good payload");
            return;
        }
        root.lastFetchFailed = false;
        root.payload = json;
        root.fetchedAtMs = Date.now();
        root.hasPayload = true;
        root._cachedLat = root.lat;
        root._cachedLon = root.lon;
        root._cachedUnitsTemp = root.unitsTemp;
        root._cachedUnitsWind = root.unitsWind;
        root._cachedUnitsPrecip = root.unitsPrecip;
        root.writeCache();
    }

    // ── The cache (D-32, T-14-02, T-14-26) ──────────────────────────────
    FileView {
        id: cacheFile
        path: Quickshell.env("HOME") + "/.local/state/theme/weather-cache.json"
        watchChanges: false
        atomicWrites: true
        printErrors: true
        onLoaded: root.loadCache()
        onLoadFailed: (error) => {
            // Never-cached / unreadable is the expected first-run state,
            // not an error condition (T-14-02).
        }
        onSaveFailed: (error) => {
            console.log("WeatherBackend: cache write failed: " + error);
        }
    }

    Component.onCompleted: cacheFile.reload()

    // Read once at construction. Parsed with the same try/catch discipline
    // as the network response; a corrupted cache is the local half of
    // T-14-02 and must be as survivable as a hostile response.
    function loadCache() {
        try {
            var raw = cacheFile.text();
            var obj = JSON.parse(raw);
            if (!obj || typeof obj !== "object" || typeof obj.fetched_at !== "number" || typeof obj.lat !== "number" || typeof obj.lon !== "number" || !obj.units || typeof obj.units !== "object") {
                console.log("WeatherBackend: cache failed shape check — treating as absent");
                return;
            }
            if (!root._payloadShapeValid(obj.payload)) {
                console.log("WeatherBackend: cached payload failed shape check — treating as absent");
                return;
            }
            // Accepted optimistically here; `_revalidateAgainstSettings()`
            // immediately below is the SINGLE place that decides whether
            // this actually matches the live state file, gated on
            // `stateFileEverLoaded` so a state-file read that is still
            // in flight at construction time can never be misread as a
            // location change (see that property's header note).
            root.payload = obj.payload;
            root.fetchedAtMs = obj.fetched_at;
            root.hasPayload = true;
            root._cachedLat = obj.lat;
            root._cachedLon = obj.lon;
            root._cachedUnitsTemp = obj.units.temp;
            root._cachedUnitsWind = obj.units.wind;
            root._cachedUnitsPrecip = obj.units.precip;
            // Quick task 260818-v3m — `city` is OPTIONAL in the shape
            // check above: every cache written before today lacks it, and
            // adding it to the mandatory-key test would discard every
            // pre-existing cache wholesale.
            if (typeof obj.city === "string" && obj.city !== "")
                root._cachedCity = obj.city;
            root._revalidateAgainstSettings();
        } catch (e) {
            console.log("WeatherBackend: cache parse failed: " + e);
        }
    }

    // Written only after a response passes its shape check (never a
    // partially-valid or malformed payload). `atomicWrites` on the FileView
    // above is the write-tearing mitigation (T-14-26); this function only
    // decides WHAT to write.
    function writeCache() {
        var obj = {
            fetched_at: root.fetchedAtMs,
            lat: root.lat,
            lon: root.lon,
            units: {
                temp: root.unitsTemp,
                wind: root.unitsWind,
                precip: root.unitsPrecip
            },
            payload: root.payload,
            city: root._cachedCity
        };
        cacheFile.setText(JSON.stringify(obj));
    }

    // ── The reverse-geocode chain (quick task 260818-v3m) ───────────────
    // Ordinary (non-singleton) child instance — GeocodeBackend has exactly
    // one consumer, this file, and needs `drawerOpen`/`coordsValid` handed
    // straight down; a shell-root mount would add a shell.qml binding for
    // zero benefit (see GeocodeBackend.qml's own header).
    GeocodeBackend {
        id: geocoder
        drawerOpen: root.drawerOpen
        lat: root.lat
        lon: root.lon
        coordsValid: root.coordsValid
        onResolved: (city) => {
            root._cachedCity = city;
            // writeCache() serialises root.payload — writing a null
            // payload would produce a cache that fails its own shape
            // check on the next load. If the geocode lands first, the
            // following applyResponse() persists the city anyway.
            if (root.hasPayload)
                root.writeCache();
        }
    }

    // The single place `geocoder.resolve()` may be called from. Guards, in
    // order: drawer must be open; coordinates must be valid; the manual
    // override (if any) short-circuits the network entirely; already-known
    // for these coordinates short-circuits it too. Called from exactly two
    // places — beside the existing `fetchIfStale()` call in
    // `_revalidateAgainstSettings()`, and beside the one in
    // `onDrawerOpenChanged`'s open branch. No new timer, no new signal, no
    // third call site.
    function _resolveCityIfNeeded() {
        if (!root.drawerOpen)
            return;
        if (!root.coordsValid)
            return;
        if (root.cityOverride !== "")
            return;
        if (root._cachedCity !== "")
            return;
        geocoder.resolve();
    }

    // ── Refresh policy (D-32) — timers exist only while the drawer is
    //    open, and any outstanding request is abandoned the instant it
    //    closes rather than left to resolve against a destroyed surface. ──
    onDrawerOpenChanged: {
        if (root.drawerOpen) {
            root.nowMs = Date.now();
            root.fetchIfStale();
            root._resolveCityIfNeeded();
        } else {
            if (root._currentXhr) {
                try {
                    root._currentXhr.abort();
                } catch (e) {
                    // already finished/aborted — nothing to do
                }
                root._currentXhr = null;
            }
            root.requestInFlight = false;
        }
    }

    Timer {
        id: clockTimer
        interval: root.clockIntervalMs
        repeat: true
        running: root.drawerOpen && root.coordsValid
        onTriggered: root.nowMs = Date.now()
    }

    Timer {
        id: refreshTimer
        interval: root.refreshIntervalMs
        repeat: true
        running: root.drawerOpen && root.coordsValid
        onTriggered: root.fetchIfStale()
    }

    // ── The WMO vocabulary, written once (RESEARCH "Don't Hand-Roll") ───
    // Every Material Symbols ligature name returned below was verified
    // present in the installed font's ligature-substitution table
    // (fontTools GSUB rlig/rclt extraction against
    // /usr/share/fonts/ttf-material-symbols-variable/MaterialSymbolsRounded
    // [FILL,GRAD,opsz,wght].ttf) before this file was committed — see
    // 14-07-SUMMARY.md for the full verified list. Day/night variants apply
    // only to the "clear" family (codes 0/1) and the "partly cloudy" family
    // (code 2) — the only two families the vocabulary actually has
    // variants for; everything else uses one symbol regardless of is_day.
    readonly property var _wmoTable: ({
            "0": { day: "clear_day", night: "clear_night", label: "Clear" },
            "1": { day: "clear_day", night: "clear_night", label: "Mainly clear" },
            "2": { day: "partly_cloudy_day", night: "partly_cloudy_night", label: "Partly cloudy" },
            "3": { day: "cloud", night: "cloud", label: "Overcast" },
            "45": { day: "foggy", night: "foggy", label: "Fog" },
            "48": { day: "foggy", night: "foggy", label: "Rime fog" },
            "51": { day: "rainy_light", night: "rainy_light", label: "Light drizzle" },
            "53": { day: "rainy", night: "rainy", label: "Drizzle" },
            "55": { day: "rainy_heavy", night: "rainy_heavy", label: "Dense drizzle" },
            "56": { day: "weather_mix", night: "weather_mix", label: "Freezing drizzle" },
            "57": { day: "weather_mix", night: "weather_mix", label: "Dense freezing drizzle" },
            "61": { day: "rainy_light", night: "rainy_light", label: "Light rain" },
            "63": { day: "rainy", night: "rainy", label: "Rain" },
            "65": { day: "rainy_heavy", night: "rainy_heavy", label: "Heavy rain" },
            "66": { day: "weather_mix", night: "weather_mix", label: "Freezing rain" },
            "67": { day: "weather_mix", night: "weather_mix", label: "Heavy freezing rain" },
            "71": { day: "weather_snowy", night: "weather_snowy", label: "Light snow" },
            "73": { day: "snowing", night: "snowing", label: "Snow" },
            "75": { day: "snowing_heavy", night: "snowing_heavy", label: "Heavy snow" },
            "77": { day: "grain", night: "grain", label: "Snow grains" },
            "80": { day: "rainy_light", night: "rainy_light", label: "Light showers" },
            "81": { day: "rainy", night: "rainy", label: "Showers" },
            "82": { day: "rainy_heavy", night: "rainy_heavy", label: "Heavy showers" },
            "85": { day: "weather_snowy", night: "weather_snowy", label: "Snow showers" },
            "86": { day: "snowing_heavy", night: "snowing_heavy", label: "Heavy snow showers" },
            "95": { day: "thunderstorm", night: "thunderstorm", label: "Thunderstorm" },
            "96": { day: "weather_hail", night: "weather_hail", label: "Thunderstorm, hail" },
            "99": { day: "weather_hail", night: "weather_hail", label: "Thunderstorm, heavy hail" }
        })

    // An unrecognised code resolves to the empty-state symbol and a neutral
    // label rather than throwing (Security V5) — never a table lookup that
    // can crash the render path.
    function symbolForWeatherCode(code, isDay) {
        var entry = root._wmoTable[String(code)];
        if (!entry)
            return "help";
        return isDay ? entry.day : entry.night;
    }

    function labelForWeatherCode(code) {
        var entry = root._wmoTable[String(code)];
        if (!entry)
            return "Unknown";
        return entry.label;
    }

    // ── Unit-aware formatters (D-31) — each keyed off the SAME state key
    //    that picked the request parameter, so the request and the
    //    rendering can never disagree about what unit a number is in. ────
    function formatTemperature(value) {
        if (!isFinite(value))
            return "—";
        var suffix = root.unitsTemp === "imperial" ? "°F" : "°C";
        return Math.round(value) + suffix;
    }

    function formatWind(value) {
        if (!isFinite(value))
            return "—";
        var suffix = root.unitsWind === "imperial" ? " mph" : " km/h";
        return Math.round(value) + suffix;
    }

    // No rendered consumer this phase — COVERAGE.md's field selection
    // carries no precipitation quantity, and widening it would rewrite a
    // matrix this plan is forbidden to widen. Wired end to end anyway: the
    // unit key already flows from the state file through the request, and
    // the first phase that renders a precipitation quantity inherits a
    // working, unit-aware formatter rather than discovering a gap.
    function formatPrecipitation(value) {
        if (!isFinite(value))
            return "—";
        var suffix = root.unitsPrecip === "imperial" ? " in" : " mm";
        return value.toFixed(1) + suffix;
    }

    function formatHourLabel(isoTime) {
        try {
            var d = new Date(isoTime.replace("T", " "));
            return Qt.formatDateTime(d, "h AP");
        } catch (e) {
            return "—";
        }
    }

    function formatDayLabel(isoDate, nowDate) {
        try {
            var d = new Date(isoDate.replace(/-/g, "/"));
            var now = nowDate || new Date(root.nowMs);
            if (d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth() && d.getDate() === now.getDate())
                return "Today";
            return Qt.formatDateTime(d, "ddd");
        } catch (e) {
            return "—";
        }
    }

    // Whole hours only (14-UI-SPEC.md's "updated Nh ago" copy).
    function formatAge(ms) {
        if (!isFinite(ms))
            return "—";
        var hours = Math.floor(ms / (60 * 60 * 1000));
        return hours + "h";
    }

    function formatClock(isoTime) {
        try {
            var d = new Date(isoTime.replace("T", " "));
            return Qt.formatDateTime(d, "h:mm AP");
        } catch (e) {
            return "—:—";
        }
    }

    // ── The three view models — one property per rendered band, so the
    //    tab reads three ready shapes and does no array arithmetic of its
    //    own. All derived from `nowMs`, never from `fetchedAtMs` — that is
    //    what keeps a cache read hours later showing the next eight hours
    //    and a self-consistent forecast rather than an elapsed window. ────
    readonly property var current: {
        if (!root.hasPayload || !root.payload || !root.payload.current)
            return null;
        var c = root.payload.current;
        var d = root.payload.daily;
        var isDay = c.is_day !== 0;
        var code = c.weather_code;
        return {
            temperature: c.temperature_2m,
            feelsLike: c.apparent_temperature,
            humidity: c.relative_humidity_2m,
            wind: c.wind_speed_10m,
            isDay: isDay,
            symbol: root.symbolForWeatherCode(code, isDay),
            label: root.labelForWeatherCode(code),
            sunrise: (d && Array.isArray(d.sunrise) && d.sunrise.length > 0) ? d.sunrise[0] : null,
            sunset: (d && Array.isArray(d.sunset) && d.sunset.length > 0) ? d.sunset[0] : null
        };
    }

    // Exactly hourColumns entries, located by searching the returned time
    // array for the current hour (never by index arithmetic, so a shifted
    // array cannot silently offset the whole strip). Short of a full
    // window, the short list is published as-is — the tab renders its
    // fixed cells with placeholders in the empty slots.
    readonly property var hourlyWindow: {
        if (!root.hasPayload || !root.payload || !root.payload.hourly)
            return [];
        var h = root.payload.hourly;
        if (!Array.isArray(h.time) || !Array.isArray(h.temperature_2m))
            return [];
        var now = new Date(root.nowMs);
        var startIdx = 0;
        for (var i = 0; i < h.time.length; i++) {
            var t = new Date(h.time[i].replace("T", " "));
            if (t.getFullYear() === now.getFullYear() && t.getMonth() === now.getMonth() && t.getDate() === now.getDate() && t.getHours() === now.getHours()) {
                startIdx = i;
                break;
            }
            if (t > now) {
                startIdx = i;
                break;
            }
        }
        var out = [];
        for (var j = startIdx; j < h.time.length && out.length < root.hourColumns; j++) {
            var code = (Array.isArray(h.weather_code) && h.weather_code[j] !== undefined) ? h.weather_code[j] : null;
            out.push({
                time: h.time[j],
                temperature: h.temperature_2m[j],
                symbol: code !== null ? root.symbolForWeatherCode(code, true) : "help",
                label: code !== null ? root.labelForWeatherCode(code) : "Unknown"
            });
        }
        return out;
    }

    // Exactly forecastDays entries, keyed by date; an entry whose date is
    // already past is dropped rather than relabelled (D-33).
    readonly property var dailyWindow: {
        if (!root.hasPayload || !root.payload || !root.payload.daily)
            return [];
        var d = root.payload.daily;
        if (!Array.isArray(d.time))
            return [];
        var now = new Date(root.nowMs);
        var todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
        var out = [];
        for (var i = 0; i < d.time.length && out.length < root.forecastDays; i++) {
            var dayDate = new Date(d.time[i].replace(/-/g, "/"));
            if (dayDate.getTime() < todayStart)
                continue;
            var code = (Array.isArray(d.weather_code) && d.weather_code[i] !== undefined) ? d.weather_code[i] : null;
            out.push({
                date: d.time[i],
                tempMax: Array.isArray(d.temperature_2m_max) ? d.temperature_2m_max[i] : NaN,
                tempMin: Array.isArray(d.temperature_2m_min) ? d.temperature_2m_min[i] : NaN,
                symbol: code !== null ? root.symbolForWeatherCode(code, true) : "help",
                label: code !== null ? root.labelForWeatherCode(code) : "Unknown"
            });
        }
        return out;
    }

    // ── The eyebrow's resolution chain (quick task 260818-v3m) ──────────
    // Free, zero-network fallback: `timezone=auto` is already in
    // buildRequestUrl(), so every response carries `payload.timezone`
    // (e.g. "Africa/Cairo"). Last "/" segment with every "_" replaced by a
    // space is a usable name with no network at all.
    function _cityFromTimezone() {
        if (!root.hasPayload || !root.payload || typeof root.payload.timezone !== "string" || root.payload.timezone.trim() === "")
            return "";
        var parts = root.payload.timezone.split("/");
        return parts[parts.length - 1].replace(/_/g, " ").trim();
    }

    // Resolution order, first hit wins: manual override -> geocoded
    // (cached) -> timezone fallback -> nothing (no placeholder dash —
    // the eyebrow simply does not render).
    readonly property string cityLabel: {
        if (root.cityOverride !== "")
            return root.cityOverride;
        if (root._cachedCity !== "")
            return root._cachedCity;
        var tz = root._cityFromTimezone();
        if (tz !== "")
            return tz;
        return "";
    }

    // Not decoration: the timezone fallback and the geocode return the
    // SAME string for this operator ("Africa/Cairo" -> "Cairo"), so
    // without this there is no way to tell which path actually ran.
    readonly property string cityLabelSource: {
        if (root.cityOverride !== "")
            return "override";
        if (root._cachedCity !== "")
            return "geocoded";
        if (root._cityFromTimezone() !== "")
            return "timezone";
        return "";
    }

    onCityLabelSourceChanged: {
        console.log("WeatherBackend: cityLabelSource = " + root.cityLabelSource);
    }
}
