// GeocodeBackend.qml — the second fenced host (quick task 260818-v3m).
// Extended (quick-260826-1n9 Task 7, D-9) to carry BOTH directions of that
// one host: reverse geocode (coordinates -> city, unchanged) AND forward
// geocode (a typed city -> coordinates, `resolveName()` below). Nominatim's
// `/search` path is the SAME host this file already owns, so the
// one-host-per-fenced-file rule holds with no new host and no new privacy
// surface — only a second path on the existing one.
//
// ── The one-host-per-fenced-file rule ────────────────────────────────────
// This is the ONE place in the repository from which a reverse- OR
// forward-geocode request may be issued. `WeatherBackend.qml` remains the
// one place a forecast request may be issued, against its own DIFFERENT
// Open-Meteo host (see that file's `forecastEndpoint`). The fence that
// used to read "no location lookup of any kind exists in this tree" is
// now "one host per fenced file" — this file carries every geocode
// request, in both directions, and nothing else does; see
// `WeatherBackend.qml`'s own header for its half of this correction.
//
// ── Privacy ───────────────────────────────────────────────────────────────
// The operator's coordinates now reach a SECOND host, `nominatim.
// openstreetmap.org`, in addition to the forecast host. That is a real
// change from the previous single-host design and is stated here plainly,
// not buried: every reverse-geocode request sends `lat`/`lon` to the OSM
// Foundation's Nominatim instance, and every forward-geocode request
// (Task 7) sends a TYPED CITY NAME to the same instance.
//
// ── Rate policy (restated for BOTH directions) ────────────────────────────
// Nominatim's published usage policy requires a descriptive `User-Agent`
// and caps usage at roughly one request per second. The reverse direction
// issues a lookup only once per coordinate change
// (`WeatherBackend.qml`'s `_resolveCityIfNeeded()`). The forward direction
// (Task 7) fires ONLY on an explicit city commit from the settings
// window's `TextRow` — never on a timer, a refresh, a summon, or a
// keystroke. Both sit trivially inside Nominatim's budget. Neither call
// must EVER be moved into the forecast fetch loop or onto a timer — this
// comment exists so nobody later "optimises" either one there.
//
// ── `accept-language=en` is load-bearing ────────────────────────────────
// Measured live against the operator's real coordinates: without this
// parameter, Nominatim returns the LOCAL-LANGUAGE name (e.g. "القاهرة"
// instead of "Cairo"). It is not cosmetic and must not be dropped.
//
// ── D-41 widget-state register ───────────────────────────────────────────
// "populated" | "pending" | "empty" — carried by every `modules/dashboard/`
// file, including non-visual backends like this one.
//
// Root type `Scope` (from `Quickshell`, NOT `Item`) — non-visual, no timer,
// no `FileView`; this file opens no file, so `Quickshell.Io` is not
// imported. Mounted as an ordinary (non-singleton) child instance of
// `WeatherBackend.qml`, not at shell root — see that file's architecture
// note for why (exactly one consumer, no timer of its own).
import QtQuick
import Quickshell

Scope {
    id: root

    // D-41: "populated" | "pending" | "empty"
    property string widgetState: "empty"

    // Lifecycle gate (D-32), handed down by the parent. Starts nothing
    // while false.
    property bool drawerOpen: false

    // Raw JSON values handed down from the parent — same `var`-not-`real`
    // discipline WeatherBackend.qml uses for lat/lon: a hand-edited string
    // must stay detectably non-numeric rather than silently coerce to zero.
    property var lat: null
    property var lon: null

    // Handed down from the parent, never recomputed here — one validator
    // in the tree, not two.
    property bool coordsValid: false

    readonly property string reverseEndpoint: "https://nominatim.openstreetmap.org/reverse"
    // Forward geocode (quick-260826-1n9 Task 7, D-9) — same host,
    // `/search` path, the standard Nominatim endpoint for name -> coordinate
    // lookups.
    readonly property string searchEndpoint: "https://nominatim.openstreetmap.org/search"
    // Descriptive, with contact, per Nominatim's usage policy.
    readonly property string userAgent: "quickshell-dashboard-weather/1.0 (+https://github.com/YahiaEng/dotfiles)"

    // Shared by BOTH directions — a forward and a reverse lookup can never
    // run concurrently either, which is a strictly SAFER posture than two
    // independent guards and keeps this file at exactly one in-flight
    // request at a time, matching Nominatim's own rate ceiling.
    property bool requestInFlight: false
    property var _currentXhr: null

    signal resolved(string city)
    // Task 7 — the forward-geocode result. `displayName` is Nominatim's
    // own full place name, carried through for a consumer that wants to
    // show what the query actually resolved to (never used to DECIDE
    // anything — `lat`/`lon` are the only two values that matter for a
    // forecast fetch).
    signal located(real lat, real lon, string displayName)

    function _updateWidgetState() {
        if (root.requestInFlight) {
            root.widgetState = "pending";
        } else {
            root.widgetState = "empty";
        }
    }
    onRequestInFlightChanged: root._updateWidgetState()

    // Same shape as WeatherBackend.qml's own buildRequestUrl() — every
    // value through encodeURIComponent.
    function buildRequestUrl() {
        var params = ["lat=" + encodeURIComponent(root.lat), "lon=" + encodeURIComponent(root.lon), "format=jsonv2", "zoom=10", "accept-language=en"];
        return root.reverseEndpoint + "?" + params.join("&");
    }

    // The only entry point. Guards, in order: drawer must be open;
    // coordinates must be valid (T-14-03's mitigation applies identically
    // here — no request on invalid coordinates, ever); no second request
    // while one is outstanding.
    function resolve() {
        if (!root.drawerOpen)
            return;
        if (!root.coordsValid)
            return;
        if (root.requestInFlight)
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
                console.log("GeocodeBackend: reverse-geocode failed with status " + xhr.status);
                return;
            }
            try {
                var json = JSON.parse(xhr.responseText);
                var city = root._cityFromResponse(json);
                if (city !== "")
                    root.resolved(city);
            } catch (e) {
                console.log("GeocodeBackend: response JSON parse failed: " + e);
            }
        };
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", root.userAgent);
        xhr.send();
    }

    // Explicit shape check before any read. First non-empty string wins:
    // address.city -> address.town -> address.village -> name. Anything
    // else (malformed shape, all-empty) returns "" — a malformed response
    // must leave the previous label untouched and never half-render, the
    // exact discipline applyResponse() already uses in the parent.
    function _cityFromResponse(json) {
        if (!json || typeof json !== "object")
            return "";
        var candidates = [];
        if (json.address && typeof json.address === "object") {
            candidates.push(json.address.city);
            candidates.push(json.address.town);
            candidates.push(json.address.village);
        }
        candidates.push(json.name);
        for (var i = 0; i < candidates.length; i++) {
            if (typeof candidates[i] === "string" && candidates[i].trim() !== "")
                return candidates[i].trim();
        }
        return "";
    }

    // ── Forward geocode (quick-260826-1n9 Task 7, D-9) ──────────────────
    function buildSearchUrl(name) {
        var params = ["q=" + encodeURIComponent(name), "format=json", "limit=1", "accept-language=en"];
        return root.searchEndpoint + "?" + params.join("&");
    }

    // The only forward entry point. Guards, in order: a non-empty trimmed
    // name; no second request while one is outstanding (the SAME
    // `requestInFlight` guard `resolve()` above uses — see that
    // property's own comment). Deliberately NOT gated on `drawerOpen`:
    // that gate exists so the dashboard's REVERSE lookup does not fire
    // while the drawer is closed, but a settings-window city commit has
    // nothing to do with the drawer — gating it there would make the
    // field silently do nothing whenever the dashboard happens to be
    // shut.
    function resolveName(name) {
        var trimmed = String(name || "").trim();
        if (trimmed === "")
            return;
        if (root.requestInFlight)
            return;

        root.requestInFlight = true;
        var url = root.buildSearchUrl(trimmed);
        var xhr = new XMLHttpRequest();
        root._currentXhr = xhr;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            root.requestInFlight = false;
            root._currentXhr = null;
            if (xhr.status !== 200) {
                console.log("GeocodeBackend: forward geocode failed with status " + xhr.status);
                return;
            }
            try {
                var json = JSON.parse(xhr.responseText);
                var loc = root._locationFromSearchResponse(json);
                if (loc)
                    root.located(loc.lat, loc.lon, loc.displayName);
                else
                    console.log("GeocodeBackend: forward geocode returned no usable result for \"" + trimmed + "\"");
            } catch (e) {
                console.log("GeocodeBackend: forward-geocode response JSON parse failed: " + e);
            }
        };
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", root.userAgent);
        xhr.send();
    }

    // Explicit shape check before any read, the same discipline
    // `_cityFromResponse()` above uses. Nominatim's `/search` returns an
    // ARRAY (unlike `/reverse`'s single object) — `limit=1` keeps it to at
    // most one entry, but an empty array (no match) is a real, expected
    // response, not a parse failure.
    function _locationFromSearchResponse(json) {
        if (!Array.isArray(json) || json.length === 0)
            return null;
        var first = json[0];
        if (!first || typeof first !== "object")
            return null;
        var lat = parseFloat(first.lat);
        var lon = parseFloat(first.lon);
        if (!isFinite(lat) || !isFinite(lon))
            return null;
        var displayName = (typeof first.display_name === "string") ? first.display_name : "";
        return {
            lat: lat,
            lon: lon,
            displayName: displayName
        };
    }

    // Abandon any outstanding request — used both when the drawer closes
    // (below) and by the parent when the coordinates change underneath an
    // in-flight lookup (WeatherBackend.qml's `_revalidateAgainstSettings()`
    // mismatch branch): a stale response resolving after that point would
    // otherwise land against the NEW coordinates' cache as if it were a
    // fresh answer.
    function abort() {
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

    // Zero idle footprint (D-32) — abandon any outstanding request the
    // instant the drawer closes rather than leave it to resolve against a
    // torn-down consumer, exactly as the parent does for its own request.
    onDrawerOpenChanged: {
        if (!root.drawerOpen)
            root.abort();
    }
}
