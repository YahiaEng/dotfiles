// NewsBackend.qml — the notification centre's News-tab feed fetcher (quick
// task 260819-6oy). Root type `Scope` (from `Quickshell`, NOT `Item`) —
// non-visual, mirrors WeatherBackend.qml's own root-type rationale exactly:
// `Scope` renders nothing and mounts cleanly under `ShellRoot` with no
// window, which is what lets the two `FileView` blocks below be declared as
// plain children.
//
// ── The fence, widened (this file's own recorded exception) ─────────────
// `WeatherBackend.qml`/`GeocodeBackend.qml` each fence a SINGLE literal host
// string in a `readonly property string`, verified by a grep that exactly
// one `.qml` file names it. That shape does not fit here: this file's feed
// hosts live in an OPERATOR-EDITABLE JSON file (`news-sources.json`) by
// design (locked decision 2 in .planning/notes/news-tab-feed-parsing.md),
// not in QML — a literal-host fence is structurally impossible to apply to
// a list the operator can freely edit.
//
// The rule is therefore widened, deliberately and recorded here exactly as
// quick task 260818-v3m recorded its own correction rather than leaving a
// stale claim standing: `NewsBackend.qml` is the ONE `.qml` file from which
// a feed request may be issued (verified by grep: exactly three `.qml`
// files in this tree construct an `XMLHttpRequest`, and this is the third).
// Because the host list is operator-editable, the literal-host fence is
// replaced by a SCHEME ALLOWLIST — `https://` only — enforced at TWO
// separate points: once at source validation (`_validSources()` — a
// non-https *source* is never fetched) and again at item acceptance
// (`_parseFeed()`'s acceptance filter — a non-https *link* in a feed
// response never enters the model). Two enforcement points because they
// guard two different attack surfaces: a mistyped/hostile source entry, and
// a hostile/compromised feed response from an otherwise-trusted source.
// The three default host strings (feeds.bbci.co.uk, feeds.npr.org, lwn.net)
// appear in exactly two places in this repo: `stow.sh`'s seed block, and
// this comment — no other `.qml` file names any feed host.
//
// ── Why the parser is a hand-rolled walk, not Qt's built-in XML list model
//    (identifiers deliberately NOT spelled out verbatim below — see why at
//    the end of this section) ─────────────────────────────────────────────
// Measured on this host (quickshell 0.3.0-2, qt6-declarative 6.11.1-3) and
// recorded in .planning/notes/news-tab-feed-parsing.md (§2/§3): Qt6's
// built-in XML-backed list-model component is RULED OUT for this feature.
// It lost its in-memory string-parse property in Qt6 (only a URL `source`
// remains — no in-memory string can be parsed at all), and, more
// fundamentally, exposes no per-row read method of its own: only
// `reload()`/`errorString()`. Without a read method it can only ever drive
// a view delegate directly — no filtering, no merging multiple sources, no
// sort-by-date, no persisting to a cache file. Qt's QML DOM also carries no
// by-tag-name descendant-lookup method at all (the actual thrower the
// first exploratory probe hit, per the design note) — every tag lookup
// below therefore walks `childNodes` by hand via `_childrenNamed()`.
//
// Do not "simplify" this back toward either of those two APIs — read the
// design note's §2/§3 for their exact identifiers and measured limits
// before reconsidering; both were tried live and both are structurally
// unusable for this feature. Their literal identifiers are deliberately
// NOT typed in this file: this file's own fence-verification grep (see
// this quick task's PLAN.md, Task 2 Verify) asserts a zero-count for both
// exact strings anywhere in this file, so writing them here — even in a
// warning comment — would make an honest gate report a false failure. The
// design note above is the citable source of truth for their names.
//
// CDATA needs no special handling: `_textOf()` concatenates every child
// `nodeValue`, which is transparent to CDATA sections (measured against
// BBC World, which wraps every `<title>` in CDATA and extracts correctly).
//
// ── Declaration order is load-bearing (quick task 260819-426) — READ THIS
//    FIRST before moving anything in this file ────────────────────────────
// `Component.onCompleted: cacheFile.reload()` fires during construction;
// its `onLoaded` runs `loadCache()`, which reads/writes several of this
// object's own members. Quick task 260819-426 cost a full debug cycle to
// exactly this class of bug in a sibling backend: a member declared BELOW
// its own construction-time call site throws
//
//   TypeError: Property '_x' of object NewsBackend_QMLTYPE_NN is not a
//   function
//
// — a log line that lives ONLY in ~/.cache/quickshell.log (the systemd
// unit journals nothing; `journalctl --user -u quickshell` is empty for
// this class of error). The visible symptom is not an error dialog but a
// silently empty News tab, which is exactly the "plausible wrong answer"
// this repo's guard-logging discipline exists to prevent.
//
// Therefore: EVERY property and EVERY function in this file is declared
// ABOVE the two `FileView` blocks near the bottom. Do not "tidy" the
// functions down to the bottom of the file — that reintroduces 260819-426.
//
// ── The gate (D-32) ────────────────────────────────────────────────────
// `centreOpen` is handed down from shell.qml, bound to
// `NotifServer.centreOpen` — the same lifecycle-gate shape every wave-3
// backend in this shell already carries. Zero timers exist in this file
// (unlike WeatherBackend's refreshTimer/clockTimer) and zero network
// activity occurs while `centreOpen` is false: `refresh()`'s own first
// guard refuses to run, and `onCentreOpenChanged`'s close branch calls
// `abort()` on any outstanding request the instant the centre closes.
//
// ── The caps, and why they exist ──────────────────────────────────────
// The source list is operator-editable (`news-sources.json`), so every
// bound below is defence-in-depth against a fat-fingered or hostile entry,
// not premature optimisation: `maxSources` (8, hard — not read from the
// JSON at all), `maxItemsPerSource`/`maxItemsTotal`/`ttlMs` (read from the
// JSON but clamped to a hard floor/ceiling so a bad value can never turn
// this into an unbounded fetch), `maxResponseBytes` (2MB, hard).
//
// ── D-41 widget-state register ────────────────────────────────────────
// `"populated" | "pending" | "empty"`, the same three-state vocabulary
// every modules/dashboard/ file carries, including non-visual backends
// like this one and WeatherBackend.qml.
//
// ── The three default hosts, named (second and last place outside
//    stow.sh) ───────────────────────────────────────────────────────────
// BBC World (feeds.bbci.co.uk/news/world/rss.xml), NPR
// (feeds.npr.org/1001/rss.xml), LWN (lwn.net/headlines/newrss) — all three
// public, keyless RSS endpoints, seeded by stow.sh into news-sources.json.
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    // ── D-41 register ────────────────────────────────────────────────
    property string widgetState: "empty"

    // ── The gate (D-32) — handed down from shell.qml ───────────────────
    property bool centreOpen: false

    // Measured allowed by this Qt build (260818-v3m's binary inspection:
    // "user-agent" is not in the QML-XHR forbidden-header table).
    readonly property string userAgent: "quickshell-notif-centre-news/1.0 (+https://github.com/YahiaEng/dotfiles)"
    // ── The fence, widened — see header ─────────────────────────────────
    readonly property string allowedScheme: "https://"

    property var items: [] // merged, sorted, capped, from the last successful run
    // ── LIVE-MEASURED CORRECTION (this quick task, Task 2) ───────────────
    // Originally an imperatively-assigned `property var`, republished from
    // `sourcesFile.onLoaded` via `root.sources = root._validSources();`.
    // Live on this host that raced: `_validSources()` read
    // `newsState.sources` as not-yet-an-array (still its declared `[]`
    // default) at the exact instant `onLoaded` fired, because the child
    // `JsonAdapter`'s own property updates had not yet settled — the SAME
    // "a child's binding lags the parent's own signal" class this file's
    // `onCentreOpenChanged` comment already names, just hit from the
    // opposite direction (parent reading a child too early, not a child
    // reading a parent too early). A readonly COMPUTED property re-derives
    // automatically from `newsState.sources` on every change QML's own
    // dependency tracking observes through this function call, with no
    // race window at all — there is no "stale onLoaded snapshot" for a
    // binding to ever hold. `sourcesFile.onLoaded` below still sets
    // `sourcesFileEverLoaded`/updates the D-41 register; it no longer
    // republishes this property.
    readonly property var sources: root._validSources()
    property string selectedSource: "" // "" = All; else a source name

    readonly property var visibleItems: root.selectedSource === "" ? root.items : root.items.filter(function (i) {
        return i.source === root.selectedSource;
    })

    property real fetchedAtMs: 0
    // Advances only while the centre is open — frozen while closed, the
    // same discipline WeatherBackend.nowMs already uses so an age display
    // cannot tick against a torn-down surface.
    property real nowMs: Date.now()

    readonly property real ageMs: root.items.length > 0 ? (root.nowMs - root.fetchedAtMs) : Infinity
    readonly property bool isStale: root.items.length === 0 || root.ageMs > root.ttlMs

    property int requestsInFlight: 0
    property int sourcesOk: 0
    property int sourcesFailed: 0
    property string lastError: ""

    // `FileView` reads are asynchronous — mirrors WeatherBackend's own
    // `stateFileEverLoaded` race guard for the identical reason: anything
    // that compares against `sources` before the first load settles is
    // comparing against `[]`.
    property bool sourcesFileEverLoaded: false
    property bool sourcesLoadHealthy: true

    property var _runBuffer: []
    property var _activeXhrs: []

    // ── Clamped tunables — a hard floor/ceiling so a bad value in the
    //    hand-edited JSON can never become an unbounded fetch ───────────
    readonly property int maxSources: 8 // hard, not configurable
    readonly property int maxItemsPerSource: root.clamp(newsState.max_items_per_source, 1, 50)
    readonly property int maxItemsTotal: root.clamp(newsState.max_items_total, 1, 200)
    readonly property int ttlMs: root.clamp(newsState.ttl_minutes, 1, 1440) * 60 * 1000
    readonly property int maxResponseBytes: 2 * 1024 * 1024

    // D-41 register, driven from the published state below — the same
    // shape WeatherBackend.qml's own onHasPayloadChanged/
    // onRequestInFlightChanged handlers use.
    onItemsChanged: root._updateWidgetState()
    onRequestsInFlightChanged: root._updateWidgetState()

    // ── Helpers (all declared above the FileViews — see header) ─────────

    function clamp(v, lo, hi) {
        var n = Number(v);
        if (!isFinite(n))
            n = lo;
        if (n < lo)
            n = lo;
        if (n > hi)
            n = hi;
        return Math.floor(n);
    }

    // ── The DOM helpers — three small functions, no library. Qt's QML DOM
    //    has no by-tag-name descendant-lookup method at all (see this
    //    file's header); `_childrenNamed` is its replacement, scoped to
    //    direct children only (matches every call site below, which
    //    always wants a direct child, never a further descendant). ──────
    function _childrenNamed(node, name) {
        var out = [];
        if (!node || !node.childNodes)
            return out;
        for (var i = 0; i < node.childNodes.length; i++) {
            var child = node.childNodes[i];
            if (child.nodeName === name)
                out.push(child);
        }
        return out;
    }

    // Concatenates every child `nodeValue` — transparent to CDATA
    // sections (measured against BBC World's title elements).
    function _textOf(node) {
        if (!node || !node.childNodes)
            return "";
        var out = "";
        for (var i = 0; i < node.childNodes.length; i++) {
            var child = node.childNodes[i];
            if (typeof child.nodeValue === "string")
                out += child.nodeValue;
        }
        return out.trim();
    }

    // The Atom `<link href="...">` reader.
    function _attrOf(node, name) {
        if (!node || !node.attributes)
            return "";
        for (var i = 0; i < node.attributes.length; i++) {
            var attr = node.attributes[i];
            if (attr.nodeName === name)
                return attr.nodeValue;
        }
        return "";
    }

    // Covers both RSS (<rss><channel><item>) and Atom (<feed><entry>).
    // Every guard below logs before returning — a silent guard is what
    // makes total failure look like a plausible wrong answer.
    function _parseFeed(doc, sourceName) {
        if (!doc || !doc.documentElement) {
            console.log("NewsBackend: " + sourceName + " — responseXML has no documentElement, rejecting");
            return [];
        }
        var docEl = doc.documentElement;
        var rootName = docEl.nodeName;
        var rawItems = [];

        if (rootName === "rss") {
            var channels = root._childrenNamed(docEl, "channel");
            var channel = channels.length > 0 ? channels[0] : null;
            var entries = channel ? root._childrenNamed(channel, "item") : [];
            for (var i = 0; i < entries.length; i++) {
                var it = entries[i];
                var titleNodes = root._childrenNamed(it, "title");
                var linkNodes = root._childrenNamed(it, "link");
                var dateNodes = root._childrenNamed(it, "pubDate");
                rawItems.push({
                    title: root._textOf(titleNodes[0]),
                    link: root._textOf(linkNodes[0]),
                    dateStr: dateNodes.length > 0 ? root._textOf(dateNodes[0]) : ""
                });
            }
        } else if (rootName === "feed") {
            var atomEntries = root._childrenNamed(docEl, "entry");
            for (var j = 0; j < atomEntries.length; j++) {
                var e = atomEntries[j];
                var titleN = root._childrenNamed(e, "title");
                var linkNs = root._childrenNamed(e, "link");
                var chosenLink = "";
                for (var k = 0; k < linkNs.length; k++) {
                    var rel = root._attrOf(linkNs[k], "rel");
                    if (rel === "" || rel === "alternate") {
                        chosenLink = root._attrOf(linkNs[k], "href");
                        break;
                    }
                }
                if (chosenLink === "" && linkNs.length > 0)
                    chosenLink = root._attrOf(linkNs[0], "href");
                var updatedN = root._childrenNamed(e, "updated");
                var publishedN = root._childrenNamed(e, "published");
                var dateStr = updatedN.length > 0 ? root._textOf(updatedN[0]) : (publishedN.length > 0 ? root._textOf(publishedN[0]) : "");
                rawItems.push({
                    title: root._textOf(titleN[0]),
                    link: chosenLink,
                    dateStr: dateStr
                });
            }
        } else {
            console.log("NewsBackend: " + sourceName + " — unrecognised root element <" + rootName + ">, rejecting");
            return [];
        }

        // ── Acceptance filter — the second https enforcement point (see
        //    header). Never drop an item for an unparseable date; it
        //    sorts last (dateMs 0) and still shows. ───────────────────
        var accepted = [];
        var rejected = 0;
        for (var m = 0; m < rawItems.length; m++) {
            var raw = rawItems[m];
            if (typeof raw.title !== "string" || raw.title === "" || typeof raw.link !== "string" || raw.link.indexOf(root.allowedScheme) !== 0) {
                rejected++;
                continue;
            }
            var parsedDate = Date.parse(raw.dateStr);
            var dateMs = isNaN(parsedDate) ? 0 : parsedDate;
            accepted.push({
                title: raw.title,
                link: raw.link,
                dateMs: dateMs,
                source: sourceName
            });
        }
        if (rejected > 0)
            console.log("NewsBackend: " + sourceName + " — rejected " + rejected + " of " + rawItems.length + " item(s) at the acceptance filter (empty title or non-https link)");

        if (accepted.length > root.maxItemsPerSource)
            accepted = accepted.slice(0, root.maxItemsPerSource);

        return accepted;
    }

    // The first https enforcement point (see header) — also the list the
    // dropdown reads. Logs each rejection with its array index and the
    // specific reason.
    function _validSources() {
        var raw = newsState.sources;
        var candidates = [];
        // ── LIVE-MEASURED FINDING (this quick task, Task 2) ──────────────
        // A `JsonAdapter` `var` property holding a JSON ARRAY does NOT
        // deserialise into a native JS `Array` on this Qt build — measured
        // live: `Array.isArray(newsState.sources)` read `false` for a
        // genuinely well-formed three-entry array that `JSON.stringify()`
        // rendered correctly and that indexed/`.length`'d exactly like a
        // real array. Motion.qml's own `semantic: var` precedent (cited in
        // this quick task's PLAN.md) never exercised this path — that
        // property holds an OBJECT, not an array, so the same pitfall
        // never surfaced there. Duck-typing on `.length` is what every
        // loop below actually needs, and is what distinguishes "genuinely
        // absent/malformed" from "present, just not natively Array-typed".
        if (!raw || typeof raw.length !== "number") {
            console.log("NewsBackend: news-sources.json 'sources' has no usable length — treating as empty");
            return candidates;
        }
        for (var i = 0; i < raw.length; i++) {
            var s = raw[i];
            if (!s || typeof s !== "object") {
                console.log("NewsBackend: source[" + i + "] rejected — not an object");
                continue;
            }
            if (typeof s.name !== "string" || s.name === "") {
                console.log("NewsBackend: source[" + i + "] rejected — missing/empty name");
                continue;
            }
            if (typeof s.url !== "string" || s.url.indexOf(root.allowedScheme) !== 0) {
                console.log("NewsBackend: source[" + i + "] (" + (typeof s.name === "string" ? s.name : "?") + ") rejected — url is not " + root.allowedScheme);
                continue;
            }
            if (s.enabled === false) {
                console.log("NewsBackend: source[" + i + "] (" + s.name + ") disabled — skipping");
                continue;
            }
            candidates.push({
                name: s.name,
                url: s.url
            });
        }
        if (candidates.length > root.maxSources) {
            console.log("NewsBackend: " + candidates.length + " valid source(s) exceed the " + root.maxSources + "-source cap — keeping the first " + root.maxSources);
            candidates = candidates.slice(0, root.maxSources);
        }
        return candidates;
    }

    function _fetchSource(src) {
        if (!root.centreOpen) {
            console.log("NewsBackend: _fetchSource(" + src.name + ") skipped — centre closed");
            return;
        }
        // Defence in depth — should already be unreachable through
        // _validSources(); if this ever fires, the validator has a hole.
        if (src.url.indexOf(root.allowedScheme) !== 0) {
            console.log("NewsBackend: _fetchSource(" + src.name + ") aborted — url failed the allowedScheme check a second time (validator hole)");
            return;
        }

        root.requestsInFlight++;
        var xhr = new XMLHttpRequest();
        root._activeXhrs.push(xhr);
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            root.requestsInFlight--;
            var idx = root._activeXhrs.indexOf(xhr);
            if (idx !== -1)
                root._activeXhrs.splice(idx, 1);

            if (xhr.status === 0) {
                root.sourcesFailed++;
                root.lastError = "network";
                console.log("NewsBackend: " + src.name + " — network error (status 0)");
            } else if (xhr.status !== 200) {
                root.sourcesFailed++;
                root.lastError = "http " + xhr.status;
                console.log("NewsBackend: " + src.name + " — HTTP " + xhr.status);
            } else if (xhr.responseText.length > root.maxResponseBytes) {
                root.sourcesFailed++;
                root.lastError = "oversize";
                console.log("NewsBackend: " + src.name + " — response oversize (" + xhr.responseText.length + " bytes)");
            } else {
                try {
                    var parsed = root._parseFeed(xhr.responseXML, src.name);
                    root._runBuffer = root._runBuffer.concat(parsed);
                    // A source that parses cleanly but yields zero items
                    // still counts as ok — success-with-nothing is a
                    // different state from failure.
                    root.sourcesOk++;
                } catch (e) {
                    root.sourcesFailed++;
                    root.lastError = "parse";
                    console.log("NewsBackend: " + src.name + " — parse threw: " + e);
                }
            }

            if (root.requestsInFlight === 0)
                root._finishRun();
        };
        xhr.open("GET", src.url);
        xhr.setRequestHeader("User-Agent", root.userAgent);
        xhr.send();
    }

    function _finishRun() {
        // Write items ONLY if at least one source succeeded this run — if
        // every source failed, leave both items and the cache exactly as
        // they were. This is what makes "no network, open the centre,
        // still see yesterday's headlines" work rather than blanking the
        // pane (never assign a half-built/empty result over a good one).
        if (root.sourcesOk > 0) {
            var merged = root._runBuffer.slice().sort(function (a, b) {
                return b.dateMs - a.dateMs;
            });
            if (merged.length > root.maxItemsTotal)
                merged = merged.slice(0, root.maxItemsTotal);
            // Assigned in ONE statement — never incrementally. A half
            // -rendered list is the failure mode the shape-check
            // discipline throughout this file exists to prevent.
            root.items = merged;
            root.fetchedAtMs = Date.now();
            root.writeCache();
        } else {
            console.log("NewsBackend: refresh finished with 0 successful source(s) (" + root.sourcesFailed + " failed) — items and cache left untouched");
        }
        root._runBuffer = [];
        root._updateWidgetState();
    }

    // The only entry point.
    function refresh(force) {
        if (!root.centreOpen) {
            console.log("NewsBackend: refresh() skipped — centre closed");
            return;
        }
        if (root.requestsInFlight > 0) {
            console.log("NewsBackend: refresh() skipped — a fetch is already in flight");
            return;
        }
        if (!force && !root.isStale) {
            console.log("NewsBackend: refresh() skipped — cache fresh, " + Math.floor(root.ageMs / 60000) + " minute(s) old");
            return;
        }
        if (root.sources.length === 0) {
            console.log("NewsBackend: refresh() — zero valid sources configured, nothing to fetch");
            return;
        }

        root.sourcesOk = 0;
        root.sourcesFailed = 0;
        root.lastError = "";
        root._runBuffer = [];
        for (var i = 0; i < root.sources.length; i++)
            root._fetchSource(root.sources[i]);
    }

    // Zero idle footprint (D-32) — called on every centre-close.
    function abort() {
        for (var i = 0; i < root._activeXhrs.length; i++) {
            try {
                root._activeXhrs[i].abort();
            } catch (e) {
                // already finished/aborted — nothing to do
            }
        }
        root._activeXhrs = [];
        root.requestsInFlight = 0;
        root._runBuffer = [];
    }

    function _updateWidgetState() {
        if (root.requestsInFlight > 0) {
            root.widgetState = "pending";
        } else if (root.items.length > 0) {
            root.widgetState = "populated";
        } else {
            root.widgetState = "empty";
        }
    }

    // Read once at construction (Component.onCompleted below). Re-runs
    // every cached item through the SAME acceptance filter parse time
    // uses (non-empty string title, https:// link) before adopting it —
    // the cache file is world-writable by the operator and may predate a
    // schema change; re-validating costs nothing and closes the
    // "trusted local file" hole.
    function loadCache() {
        try {
            var raw = cacheFile.text();
            var obj = JSON.parse(raw);
            if (!obj || typeof obj !== "object" || typeof obj.fetched_at !== "number" || !Array.isArray(obj.items)) {
                console.log("NewsBackend: cache failed shape check — treating as absent");
                return;
            }
            var revalidated = [];
            for (var i = 0; i < obj.items.length; i++) {
                var it = obj.items[i];
                if (!it || typeof it.title !== "string" || it.title === "" || typeof it.link !== "string" || it.link.indexOf(root.allowedScheme) !== 0)
                    continue;
                revalidated.push({
                    title: it.title,
                    link: it.link,
                    dateMs: typeof it.dateMs === "number" ? it.dateMs : 0,
                    source: typeof it.source === "string" ? it.source : ""
                });
            }
            // Assigned in one go.
            root.items = revalidated;
            root.fetchedAtMs = obj.fetched_at;
        } catch (e) {
            console.log("NewsBackend: cache parse failed: " + e);
        }
    }

    function writeCache() {
        var obj = {
            fetched_at: root.fetchedAtMs,
            items: root.items
        };
        cacheFile.setText(JSON.stringify(obj));
    }

    // ── The two FileViews (declared AFTER every property and function —
    //    see header) ─────────────────────────────────────────────────────
    FileView {
        id: sourcesFile
        path: Quickshell.env("HOME") + "/.local/state/theme/news-sources.json"
        watchChanges: true
        printErrors: true
        onLoaded: {
            root.sourcesFileEverLoaded = true;
            // `root.sources` is now a readonly computed property (see its
            // own declaration comment) — it re-derives itself with no
            // race window; nothing to republish here.
            root._updateWidgetState();
        }
        onFileChanged: {
            root.sourcesLoadHealthy = true;
            reload();
        }
        onLoadFailed: error => {
            root.sourcesLoadHealthy = false;
            root.sourcesFileEverLoaded = true;
            console.log("NewsBackend: news-sources.json load failed: " + error);
        }

        // 14-02's flat-top-level-keys shape (Pitfall 5: JsonAdapter maps
        // top-level keys only, verified against Motion.qml's own
        // `semantic` var precedent for a nested array/object).
        JsonAdapter {
            id: newsState
            property var sources: []
            property int max_items_per_source: 15
            property int max_items_total: 40
            property int ttl_minutes: 15
        }
    }

    FileView {
        id: cacheFile
        path: Quickshell.env("HOME") + "/.local/state/theme/news-cache.json"
        watchChanges: false
        atomicWrites: true
        printErrors: true
        onLoaded: root.loadCache()
        onLoadFailed: error => {
            // Never-cached is the expected first-run state, not an error.
        }
        onSaveFailed: error => {
            console.log("NewsBackend: cache write failed: " + error);
        }
    }

    Component.onCompleted: cacheFile.reload()

    // ── Refresh policy (D-32) — zero network while the centre is closed.
    //    `Qt.callLater` is MANDATORY, not stylistic: `refresh()` reads
    //    `root.sources`, which derives from the child `JsonAdapter`
    //    (`newsState`) via `sourcesFile`'s own onLoaded handler — a
    //    child's binding/derived state is not yet updated inside the
    //    PARENT's own onXChanged handler (this exact bug cost a full
    //    debug cycle in quick task 260819-426;
    //    WeatherBackend._resolveCityIfNeeded() already carries the same
    //    deferral for the same reason). Deferring by one event-loop tick
    //    lets bindings settle before refresh() reads them. ──────────────
    onCentreOpenChanged: {
        if (root.centreOpen) {
            root.nowMs = Date.now();
            Qt.callLater(function () {
                root.refresh(false);
            });
        } else {
            root.abort();
        }
    }
}
