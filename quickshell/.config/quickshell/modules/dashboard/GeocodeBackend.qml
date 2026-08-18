// GeocodeBackend.qml — the second fenced host (quick task 260818-v3m).
//
// ── The one-host-per-fenced-file rule ────────────────────────────────────
// This is the ONE place in the repository from which a reverse-geocode
// request may be issued. `WeatherBackend.qml` remains the one place a
// forecast request may be issued, against a DIFFERENT host
// (`api.open-meteo.com`). The fence that used to read "no location lookup
// of any kind exists in this tree" is now "one host per fenced file" — this
// file carries the reverse-geocode host and nothing else does; see
// `WeatherBackend.qml`'s own header for its half of this correction.
//
// ── Privacy ───────────────────────────────────────────────────────────────
// The operator's coordinates now reach a SECOND host, `nominatim.
// openstreetmap.org`, in addition to `api.open-meteo.com`. That is a real
// change from the previous single-host design and is stated here plainly,
// not buried: every reverse-geocode request sends `lat`/`lon` to the OSM
// Foundation's Nominatim instance.
//
// ── Rate policy ───────────────────────────────────────────────────────────
// Nominatim's published usage policy requires a descriptive `User-Agent`
// and caps usage at roughly one request per second. This backend issues a
// lookup only once per coordinate change (`WeatherBackend.qml`'s
// `_resolveCityIfNeeded()` — never on a refresh, never on a summon, never
// on a schedule), which sits trivially inside that budget. This call must
// NEVER be moved into the forecast fetch loop or onto a timer — this
// comment exists so nobody later "optimises" it there.
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
    // Descriptive, with contact, per Nominatim's usage policy.
    readonly property string userAgent: "quickshell-dashboard-weather/1.0 (+https://github.com/YahiaEng/dotfiles)"

    property bool requestInFlight: false
    property var _currentXhr: null

    signal resolved(string city)

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

    // Zero idle footprint (D-32) — abandon any outstanding request the
    // instant the drawer closes rather than leave it to resolve against a
    // torn-down consumer, exactly as the parent does for its own request.
    onDrawerOpenChanged: {
        if (!root.drawerOpen) {
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
}
