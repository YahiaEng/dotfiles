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
// replaced by a SCHEME ALLOWLIST — `https://` only — enforced at THREE
// separate points: once at source validation (`_validSources()` — a
// non-https *source* is never fetched), again at item acceptance
// (`_parseFeed()`'s acceptance filter — a non-https *link* in a feed
// response never enters the model), and a third time at image-URL
// acceptance (`_imageOf()` — a non-https candidate image URL is dropped,
// the item itself still renders with its glyph fallback). Three
// enforcement points because they guard three different attack surfaces: a
// mistyped/hostile source entry, a hostile/compromised feed response from
// an otherwise-trusted source, and an image URL — a NEW remote-host class —
// that a hostile feed response can carry just as easily as a hostile link.
// The four default host strings (feeds.bbci.co.uk, feeds.arstechnica.com,
// itsfoss.com, www.phoronix.com) appear in exactly two places in this repo:
// `stow.sh`'s seed block, and this comment — no other `.qml` file names any
// feed host.
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
// ── Self-healing retry, derived from cache not memory (quick task
//    260819-ug4) ──────────────────────────────────────────────────────
// `refresh(force)`'s non-forced path used to gate on WHOLE-CACHE
// staleness only: if the cache was fresh, it skipped the entire refresh,
// even when one source had failed and contributed nothing that run. The
// failed source then read as a dead feed for the rest of the TTL window,
// recoverable only by the manual refresh click or by waiting the TTL out.
//
// The fix re-attempts, on every centre-open inside a fresh TTL, exactly
// the subset of `root.sources` that currently has ZERO cached headlines
// (`_sourcesNeedingRetry()`) — never the whole list, never nothing. That
// retry set is derived from CACHE CONTENTS, not from `_failedNames`:
// `_failedNames` is in-memory only and does not survive a shell restart,
// while a reloaded cache still implicitly knows which sources are empty.
// Deriving from the cache also catches a case `_failedNames` structurally
// cannot: a source that fetched and parsed cleanly but yielded zero items
// increments `sourcesOk` and never enters `_failedNames`, yet reads
// exactly like a dead feed to the operator.
//
// The trade-off: a source that legitimately, persistently publishes
// nothing is re-attempted on every centre-open. That is one bounded,
// idempotent HTTP GET behind the D-32 centre-open gate, against a list
// already hard-capped at `maxSources` (8) — cheaper than a feed silently
// reading as dead. One pathological case is worth naming: if an operator
// sets `max_items_total` below the number of configured sources, the
// round-robin selection below gives the tail sources zero slots, and
// those sources are re-attempted on every centre-open too — bounded,
// logged, and visible rather than silent.
//
// A partial run (targets a strict subset of `root.sources`) never
// advances `fetchedAtMs` — only a whole run does, so the age readout and
// the TTL clock stay honest. The publish gate keys on whether THIS run
// brought anything back (a positive per-run record, the twin of
// `_failedNames`, called `_okNames`) rather than on the run-scoped
// success counter alone, because that counter is now SEEDED with the
// sources deliberately skipped as already-healthy — a wholly-failed
// partial run must still refuse to publish.
//
// ── D-41 widget-state register ────────────────────────────────────────
// `"populated" | "pending" | "empty"`, the same three-state vocabulary
// every modules/dashboard/ file carries, including non-visual backends
// like this one and WeatherBackend.qml.
//
// ── The four default hosts, named (second and last place outside
//    stow.sh) ───────────────────────────────────────────────────────────
// BBC World (feeds.bbci.co.uk/news/world/rss.xml), Ars Technica
// (feeds.arstechnica.com/arstechnica/index), It's FOSS (itsfoss.com/rss),
// Phoronix (www.phoronix.com/rss.php) — all four public, keyless RSS
// endpoints, seeded by stow.sh into news-sources.json.
import QtQuick
import Quickshell
import Quickshell.Io
// Prefs (quick task 260825-wj2 Task 6) — the modules/-root `qs.modules`
// manifest, the same relative import Design.qml already uses.
import "../"

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

    // ── view_mode (this quick task) — a READONLY computed property
    //    derived from the file, the same shape `sources` above already
    //    settled on for the identical reason: it can never disagree with
    //    disk. Unknown or missing values fall back to "compact", per the
    //    spec. There is deliberately no writable local property here — the
    //    screen only ever shows what `setViewMode()` below actually
    //    persisted. ─────────────────────────────────────────────────────
    readonly property string viewMode: newsState.view_mode === "cards" ? "cards" : "compact"

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

    // Names of the sources that FAILED this run (network, HTTP, oversize
    // or parse). CORRECTED (quick task 260819-ug4): this is no longer
    // what the carry-forward keys on — `_carryForward()` below keys on
    // the positive record (`_okNames`) instead, because a partial run's
    // never-attempted sources are absent from `_failedNames` too but
    // still must be carried. What `_failedNames` remains for: per-run
    // failure reporting (`sourcesFailed` alone cannot name WHICH sources
    // failed) and the failed-source log line in `_fetchSource()`. Reset
    // per run alongside _runBuffer.
    property var _failedNames: []

    // The positive twin of `_failedNames` (quick task 260819-ug4) — names
    // of the sources that SUCCEEDED this run (fetched and parsed without
    // throwing). Both the publish gate and the carry-forward key on this,
    // not on `_failedNames`, because it is what stays correct in a
    // partial run: a source never attempted this run is neither ok nor
    // failed in the old two-state sense, but it must still be excluded
    // from the carry-forward exactly like a failed one. Reset per run
    // alongside _runBuffer.
    property var _okNames: []

    // How many sources this run actually attempted (quick task
    // 260819-ug4) — `root.sources.length` for a whole run, fewer for a
    // partial one. Exists only so a partial run's log lines and its
    // `fetchedAtMs` gate cannot mistake themselves for a whole run.
    property int _runSourceCount: 0

    property var _activeXhrs: []

    // ── Clamped tunables — a hard floor/ceiling so a bad value in the
    //    hand-edited JSON can never become an unbounded fetch ───────────
    readonly property int maxSources: 8 // hard, not configurable
    readonly property int maxItemsPerSource: root.clamp(newsState.max_items_per_source, 1, 50)
    readonly property int maxItemsTotal: root.clamp(newsState.max_items_total, 1, 200)
    // services.newsTtlMinutes (quick task 260825-wj2 Task 6, Services
    // page's "News cache lifetime" stepper) — 0 means "follow
    // news-sources.json"'s own ttl_minutes, Prefs' own default. The clamp
    // stays on BOTH paths — a hand-edited prefs.json cannot produce an
    // unbounded fetch cadence either way.
    readonly property int ttlMs: {
        var prefMinutes = Prefs.getValue("services.newsTtlMinutes");
        var minutes = (prefMinutes > 0) ? prefMinutes : newsState.ttl_minutes;
        return root.clamp(minutes, 1, 1440) * 60 * 1000;
    }
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

    // ── Namespace-tolerant sibling of `_childrenNamed()` (this quick
    //    task) — whether this Qt build's `responseXML` reports a
    //    namespaced tag's `nodeName` as the qualified name
    //    ("media:thumbnail") or the local name ("thumbnail") was NOT
    //    measured before writing this. Rather than guess and bet on one
    //    behaviour, this accepts a child whose `nodeName` is either exactly
    //    `localName` OR ends with `":" + localName` — correct under BOTH
    //    behaviours. The live cache-population gate in this quick task's
    //    PLAN.md (Task 1) proves end-to-end which branch actually fires. ──
    function _childrenNamedNs(node, localName) {
        var out = [];
        if (!node || !node.childNodes)
            return out;
        var suffix = ":" + localName;
        for (var i = 0; i < node.childNodes.length; i++) {
            var child = node.childNodes[i];
            var n = child.nodeName;
            if (n === localName || (typeof n === "string" && n.endsWith(suffix)))
                out.push(child);
        }
        return out;
    }

    // ── RSS 1.0 / RDF root detection. Namespace-tolerant for exactly the
    //    same unmeasured reason `_childrenNamedNs()` above is: whether this
    //    Qt build reports the root's `nodeName` as the qualified "rdf:RDF"
    //    or the local "RDF" was not measured, so this accepts both rather
    //    than betting on one. Declared here, above all three call sites
    //    (`_parseFeed`, `_feedTitleOf`, `probeSource`), per this file's
    //    helpers-above-use rule.
    function _isRdfRoot(name) {
        return name === "RDF" || (typeof name === "string" && name.endsWith(":RDF"));
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

    // ── The image extractor (this quick task) — a GENERAL preference
    //    order, no feed-specific branch anywhere: media:thumbnail, then
    //    media:content, then an image/* enclosure, then none. Format-
    //    agnostic, so both the RSS and Atom branches below call this same
    //    function. This is the THIRD https enforcement point (see header):
    //    a candidate URL that is not `root.allowedScheme` is dropped here,
    //    and only the IMAGE is dropped — the item itself is still accepted
    //    and renders its glyph fallback. ──────────────────────────────────
    function _imageOf(itemNode) {
        var candidate = "";
        var thumbs = root._childrenNamedNs(itemNode, "thumbnail");
        if (thumbs.length > 0) {
            candidate = root._attrOf(thumbs[0], "url");
        } else {
            var contents = root._childrenNamedNs(itemNode, "content");
            if (contents.length > 0) {
                candidate = root._attrOf(contents[0], "url");
            } else {
                // `enclosure` is unnamespaced in RSS — the plain lookup.
                var enclosures = root._childrenNamed(itemNode, "enclosure");
                for (var i = 0; i < enclosures.length; i++) {
                    var type = root._attrOf(enclosures[i], "type");
                    if (typeof type === "string" && type.indexOf("image/") === 0) {
                        candidate = root._attrOf(enclosures[i], "url");
                        break;
                    }
                }
            }
        }
        if (candidate === "")
            return "";
        if (candidate.indexOf(root.allowedScheme) !== 0) {
            console.log("NewsBackend: _imageOf — dropped non-https image candidate, item still accepted");
            return "";
        }
        return candidate;
    }

    // Covers RSS 2.0 (<rss><channel><item>), Atom (<feed><entry>) and
    // RSS 1.0 (<rdf:RDF><item>, items as SIBLINGS of <channel>).
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
                    dateStr: dateNodes.length > 0 ? root._textOf(dateNodes[0]) : "",
                    image: root._imageOf(it)
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
                    dateStr: dateStr,
                    // Atom feeds can carry the same media:* children as
                    // RSS — the extractor is format-agnostic, so reusing
                    // it here is not a feed-specific branch.
                    image: root._imageOf(e)
                });
            }
        } else if (root._isRdfRoot(rootName)) {
            // RSS 1.0 differs from RSS 2.0 in exactly two ways that matter
            // here, both measured against rss.slashdot.org: <item> is a
            // SIBLING of <channel> rather than nested inside it, and the
            // timestamp is Dublin Core's <dc:date> (ISO 8601) rather than
            // <pubDate>. Title and link are plain-text children exactly as
            // in RSS 2.0, so only the traversal and the date tag change —
            // everything downstream (acceptance filter, https enforcement,
            // image extraction, per-source cap) is shared unchanged.
            var rdfItems = root._childrenNamed(docEl, "item");
            for (var r = 0; r < rdfItems.length; r++) {
                var ri = rdfItems[r];
                var rdfTitleN = root._childrenNamed(ri, "title");
                var rdfLinkN = root._childrenNamed(ri, "link");
                // Namespace-tolerant, so this matches "dc:date" under a
                // qualified-name build and a bare "date" under a local-name
                // one — the same both-ways hedge _childrenNamedNs() exists for.
                var rdfDateN = root._childrenNamedNs(ri, "date");
                rawItems.push({
                    title: root._textOf(rdfTitleN[0]),
                    link: root._textOf(rdfLinkN[0]),
                    // MEASURED: the bare slashdot.org/slashdot.rdf endpoint
                    // carries no date element of any kind (0 pubDate, 0
                    // dc:date across 18 links), while the rss.slashdot.org
                    // paths carry dc:date. That needs no special case — the
                    // acceptance filter below already assigns an absent or
                    // unparseable date dateMs 0, which sorts last and still
                    // shows, deliberately.
                    dateStr: rdfDateN.length > 0 ? root._textOf(rdfDateN[0]) : "",
                    image: root._imageOf(ri)
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
            // Never reject an item for a missing or bad image — a
            // text-only source is a first-class source; the fallback tier
            // exists exactly for this.
            accepted.push({
                title: raw.title,
                link: raw.link,
                dateMs: dateMs,
                source: sourceName,
                image: raw.image
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

    // ── Persist view_mode — a surgical read-modify-write, deliberately
    //    NOT a `writeAdapter()`-style whole-object republish. `sources`
    //    is not a native JS Array on this Qt build (see the LIVE-MEASURED
    //    FINDING in `_validSources()` above) — round-tripping it through a
    //    generic re-serialise risks clobbering the operator's source list.
    //    So: read the raw text, parse it, set exactly one key, stringify,
    //    write it back — the same idiom `writeCache()` already uses.
    //    Refuses to write, with a log line, if the parsed object has no
    //    usable `sources` length, so a malformed file can never be
    //    replaced by a lossy rewrite. ────────────────────────────────────
    function setViewMode(mode) {
        var next = mode === "cards" ? "cards" : "compact";
        try {
            var raw = sourcesFile.text();
            var parsed = JSON.parse(raw);
            if (!parsed || typeof parsed !== "object" || !parsed.sources || typeof parsed.sources.length !== "number") {
                console.log("NewsBackend: setViewMode(" + next + ") refused — news-sources.json has no usable 'sources' length");
                return;
            }
            parsed.view_mode = next;
            sourcesFile.setText(JSON.stringify(parsed, null, 2));
        } catch (e) {
            console.log("NewsBackend: setViewMode(" + next + ") failed: " + e);
        }
    }

    // ── The shared transport (D-5, this quick task) — the ONE place an
    //    XMLHttpRequest is constructed in this file. `_fetchSource()`
    //    (the refresh run) and `probeSource()` (the add-flow's live
    //    check) both call this; neither constructs its own request. It
    //    registers in `_activeXhrs` so the existing `abort()` on
    //    centre-close kills either caller's in-flight request for free.
    //    `onDone` receives a single result object: `ok` (bool), `reason`
    //    (a code, "" on success), `detail` (extra context — the HTTP
    //    status or the oversize byte count), `doc` (the parsed
    //    `responseXML`, null on failure). Reason codes on failure:
    //    "scheme" (refused synchronously, before any request is issued),
    //    "network" (status 0), "http" (detail carries the status),
    //    "oversize" (response longer than maxResponseBytes, detail
    //    carries the length). Never "parse" — parsing is the caller's
    //    job, not this function's. ────────────────────────────────────
    function _fetchXml(url, onDone) {
        if (typeof url !== "string" || url.indexOf(root.allowedScheme) !== 0) {
            console.log("NewsBackend: shared transport refused synchronously — url is not " + root.allowedScheme);
            onDone({
                ok: false,
                reason: "scheme",
                detail: "",
                doc: null
            });
            return;
        }
        var xhr = new XMLHttpRequest();
        root._activeXhrs.push(xhr);
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            var idx = root._activeXhrs.indexOf(xhr);
            if (idx !== -1)
                root._activeXhrs.splice(idx, 1);

            if (xhr.status === 0) {
                onDone({
                    ok: false,
                    reason: "network",
                    detail: "",
                    doc: null
                });
            } else if (xhr.status !== 200) {
                onDone({
                    ok: false,
                    reason: "http",
                    detail: String(xhr.status),
                    doc: null
                });
            } else if (xhr.responseText.length > root.maxResponseBytes) {
                onDone({
                    ok: false,
                    reason: "oversize",
                    detail: String(xhr.responseText.length),
                    doc: null
                });
            } else {
                onDone({
                    ok: true,
                    reason: "",
                    detail: "",
                    doc: xhr.responseXML
                });
            }
        };
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", root.userAgent);
        xhr.send();
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

        // requestsInFlight is incremented BEFORE calling the shared
        // transport, deliberately: the transport's own scheme guard can
        // fail SYNCHRONOUSLY (see its own comment above), and
        // incrementing after a transport that can fail synchronously
        // would let _finishRun() fire after the first source while the
        // rest of the loop in refresh() has not started yet. The
        // transport's own scheme guard is now unreachable from this run
        // path — the guard immediately above already refused — but it
        // stays as the transport's own defence-in-depth.
        root.requestsInFlight++;
        root._fetchXml(src.url, function (result) {
            root.requestsInFlight--;

            if (!result.ok && result.reason === "network") {
                root.sourcesFailed++;
                root._failedNames.push(src.name);
                root.lastError = "network";
                console.log("NewsBackend: " + src.name + " — network error (status 0)");
            } else if (!result.ok && result.reason === "http") {
                root.sourcesFailed++;
                root._failedNames.push(src.name);
                root.lastError = "http " + result.detail;
                console.log("NewsBackend: " + src.name + " — HTTP " + result.detail);
            } else if (!result.ok && result.reason === "oversize") {
                root.sourcesFailed++;
                root._failedNames.push(src.name);
                root.lastError = "oversize";
                console.log("NewsBackend: " + src.name + " — response oversize (" + result.detail + " bytes)");
            } else if (!result.ok) {
                // "scheme" — unreachable from this path (see the guard
                // above), kept as defence-in-depth so a future change to
                // the transport cannot silently drop a source with no
                // log line at all.
                root.sourcesFailed++;
                root._failedNames.push(src.name);
                root.lastError = result.reason;
                console.log("NewsBackend: " + src.name + " — " + result.reason);
            } else {
                try {
                    var parsed = root._parseFeed(result.doc, src.name);
                    root._runBuffer = root._runBuffer.concat(parsed);
                    // A source that parses cleanly but yields zero items
                    // still counts as ok — success-with-nothing is a
                    // different state from failure. _okNames (quick task
                    // 260819-ug4) records the positive per-run result
                    // alongside the counter.
                    root.sourcesOk++;
                    root._okNames.push(src.name);
                } catch (e) {
                    root.sourcesFailed++;
                    root._failedNames.push(src.name);
                    root.lastError = "parse";
                    console.log("NewsBackend: " + src.name + " — parse threw: " + e);
                }
            }

            if (root.requestsInFlight === 0)
                root._finishRun();
        });
    }

    // ── Self-healing retry set (quick task 260819-ug4) — see the header
    //    section for the full design rationale. Returns the subset of
    //    root.sources whose name appears on zero items in root.items.
    //    Uses an array + indexOf, NOT a plain object used as a map — an
    //    operator-authored source name such as "constructor" or
    //    "__proto__" collides with Object.prototype and would silently
    //    produce a wrong answer; indexOf on a list capped at 8 sources
    //    and 200 items has no such hazard, and it matches the
    //    _failedNames.indexOf idiom this file already uses. ────────────
    function _sourcesNeedingRetry() {
        var haveNames = [];
        for (var i = 0; i < root.items.length; i++) {
            if (haveNames.indexOf(root.items[i].source) === -1)
                haveNames.push(root.items[i].source);
        }
        var retry = [];
        for (var j = 0; j < root.sources.length; j++) {
            if (haveNames.indexOf(root.sources[j].name) === -1)
                retry.push(root.sources[j]);
        }
        return retry;
    }

    // ── Carry-forward, keyed on the positive record (quick task
    //    260819-ug4) — replaces the _failedNames-keyed loop that used to
    //    live inline in _finishRun(). An item is carried when BOTH hold:
    //    its source is the name of a currently-configured enabled source
    //    (i.e. it appears in root.sources — this is what drops a
    //    hand-removed source's items, exactly as the old _failedNames
    //    keying happened to achieve), AND its source is NOT in
    //    root._okNames. In a whole run this is byte-identical to the old
    //    behaviour (every source is either ok or failed); in a partial
    //    run the sources never attempted this run are also not in
    //    _okNames, so their items are carried too — which is precisely
    //    what stops a partial run clobbering the healthy sources. ──────
    function _carryForward() {
        var configuredNames = [];
        for (var i = 0; i < root.sources.length; i++)
            configuredNames.push(root.sources[i].name);
        var carried = [];
        for (var c = 0; c < root.items.length; c++) {
            var it = root.items[c];
            if (configuredNames.indexOf(it.source) !== -1 && root._okNames.indexOf(it.source) === -1)
                carried.push(it);
        }
        return carried;
    }

    function _finishRun() {
        // Write items ONLY if THIS run actually brought something back —
        // if every attempted source failed, leave both items and the
        // cache exactly as they were. This is what makes "no network,
        // open the centre, still see yesterday's headlines" work rather
        // than blanking the pane (never assign a half-built/empty result
        // over a good one). The gate keys on the positive per-run record
        // (quick task 260819-ug4), not on the run-scoped success counter
        // alone: refresh() below now SEEDS that counter with the sources
        // deliberately skipped as already-healthy, so a counter-only gate
        // would let a wholly-failed partial run take this branch.
        if (root._okNames.length > 0) {
            // ── Fair selection BEFORE the cap (bug fix 2026-08-19) ───────
            // A plain global sort-then-truncate starves whichever source
            // publishes slowest. MEASURED with the four default sources:
            // 57 candidates cut to 40 by pure recency left BBC 15,
            // Phoronix 12, Ars 10 and LWN **3** — LWN had been showing 15
            // when only three sources existed and the candidate count
            // happened to equal the cap exactly (15+15+10=40, nothing
            // cut), which is why this only surfaced once a fourth source
            // was added. The starvation scaled with how many high-volume
            // feeds sat beside a low-volume one, so it would have got
            // worse with every source added, silently.
            //
            // Selection is now round-robin BY SOURCE: take each source's
            // newest unused item in turn, then each source's next, until
            // the cap. Every source is therefore guaranteed roughly
            // maxItemsTotal / sourceCount slots and none can be evicted
            // by a noisier neighbour. Display order is unaffected — the
            // SELECTED set is sorted by date afterwards, so the pane
            // still reads strictly newest-first.
            var byNewest = function (a, b) {
                return b.dateMs - a.dateMs;
            };

            // ── Partial-failure carry-forward (bug fix 2026-08-19) ───────
            // A run where SOME sources fail used to publish only the
            // survivors, silently deleting every headline belonging to a
            // source that happened to error — the whole feed vanished
            // from the pane until some later run happened to succeed.
            // The zero-successful-sources case was already guarded (the
            // else branch below leaves items and cache untouched); the
            // partial case was not, and it is the common one: measured 4
            // `network error (status 0)` events across 24 runs on this
            // host, BBC and LWN, i.e. transient and per-source rather
            // than all-or-nothing.
            //
            // Items belonging to a source that failed THIS run are
            // carried over from the previous published set, so a blip on
            // one feed can no longer empty it. They cannot collide with
            // fresh items, because a failed source contributed nothing to
            // _runBuffer by definition. A source that is REMOVED from
            // news-sources.json is not carried: it never appears in
            // _failedNames, because no request is ever issued for it.
            // ── Carry-forward, now keyed on the positive record (quick
            //    task 260819-ug4 generalises the 2026-08-19 bug fix above
            //    to a partial run — see _carryForward()'s own comment for
            //    the full rationale) ──────────────────────────────────
            var carried = root._carryForward();
            if (carried.length > 0) {
                var carriedSources = [];
                for (var cc = 0; cc < carried.length; cc++) {
                    if (carriedSources.indexOf(carried[cc].source) === -1)
                        carriedSources.push(carried[cc].source);
                }
                console.log("NewsBackend: carried " + carried.length + " item(s) forward from " + carriedSources.length + " source(s) not refreshed this run: " + carriedSources.join(", "));
            }
            var pool = root._runBuffer.concat(carried);

            var bucket = {};
            var order = [];
            for (var i = 0; i < pool.length; i++) {
                var it = pool[i];
                if (bucket[it.source] === undefined) {
                    bucket[it.source] = [];
                    order.push(it.source);
                }
                bucket[it.source].push(it);
            }
            for (var s = 0; s < order.length; s++)
                bucket[order[s]].sort(byNewest);

            var picked = [];
            var round = 0;
            var drained = false;
            while (picked.length < root.maxItemsTotal && !drained) {
                drained = true;
                for (var t = 0; t < order.length && picked.length < root.maxItemsTotal; t++) {
                    var lane = bucket[order[t]];
                    if (round < lane.length) {
                        picked.push(lane[round]);
                        drained = false;
                    }
                }
                round++;
            }
            var merged = picked.sort(byNewest);
            // Assigned in ONE statement — never incrementally. A half
            // -rendered list is the failure mode the shape-check
            // discipline throughout this file exists to prevent.
            root.items = merged;
            // The whole-cache timestamp advances ONLY on a whole run
            // (quick task 260819-ug4) — every configured source was
            // attempted this run, i.e. _runSourceCount equals
            // root.sources.length. A partial run (the self-healing retry
            // touches only the sources with zero cached headlines) must
            // NOT advance it: doing so would both lie in the age readout
            // (claiming the healthy sources were just re-checked, when
            // they were deliberately skipped) and push the TTL out,
            // indefinitely deferring the full refresh the healthy sources
            // still need. writeCache() below still runs unconditionally
            // in this branch, so a healed partial survives a restart even
            // though fetchedAtMs did not move.
            if (root._runSourceCount === root.sources.length) {
                root.fetchedAtMs = Date.now();
            } else {
                console.log("NewsBackend: partial run (" + root._runSourceCount + " of " + root.sources.length + " source(s)) — fetchedAtMs left unchanged");
            }
            root.writeCache();
        } else {
            console.log("NewsBackend: refresh finished with 0 successful source(s) this run (" + root._runSourceCount + " of " + root.sources.length + " configured source(s) attempted, " + root.sourcesFailed + " failed) — items and cache left untouched");
        }
        root._runBuffer = [];
        root._okNames = [];
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
        if (root.sources.length === 0) {
            console.log("NewsBackend: refresh() — zero valid sources configured, nothing to fetch");
            return;
        }

        // ── The retry set (quick task 260819-ug4) — see the header
        //    section for the full design rationale. A forced run (the
        //    manual refresh button) and a genuinely stale cache both
        //    still run the WHOLE source list, unchanged from before this
        //    quick task. Only the fresh-cache, non-forced path narrows
        //    to _sourcesNeedingRetry() — the self-healing addition. ────
        var targets = root.sources;
        if (!force && !root.isStale) {
            targets = root._sourcesNeedingRetry();
            if (targets.length === 0) {
                console.log("NewsBackend: refresh() — cache fresh, " + Math.floor(root.ageMs / 60000) + " minute(s) old, every source has headlines — nothing to re-attempt");
                return;
            }
            var retryNames = [];
            for (var n = 0; n < targets.length; n++)
                retryNames.push(targets[n].name);
            console.log("NewsBackend: refresh() — cache fresh, " + Math.floor(root.ageMs / 60000) + " minute(s) old, but re-attempting " + targets.length + " source(s) with no cached headlines: " + retryNames.join(", "));
        }

        // Seeded, not zeroed (quick task 260819-ug4): sourcesOk starts at
        // the number of sources deliberately NOT in targets — they were
        // skipped because they already have cached headlines, i.e. they
        // are known good. This is what keeps NewsPane.qml's "N of M
        // sources unreachable" footer honest: M stays the full configured
        // source count rather than collapsing to the retried subset. For
        // a whole run this is 0, exactly as before this quick task.
        root.sourcesOk = root.sources.length - targets.length;
        root.sourcesFailed = 0;
        root.lastError = "";
        root._runBuffer = [];
        root._failedNames = [];
        root._okNames = [];
        root._runSourceCount = targets.length;
        for (var i = 0; i < targets.length; i++)
            root._fetchSource(targets[i]);
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
        // Reset alongside _runBuffer (quick task 260819-ug4) — a
        // centre-close mid-run must not leave a stale positive record for
        // the next run's carry-forward to read.
        root._okNames = [];
        root._runSourceCount = 0;
        // D-5 — kills an in-flight probe for free (it shares
        // _activeXhrs). The in-flight callback's own probeState guard
        // then makes the late DONE a no-op.
        if (root.probeState === "probing")
            root.probeState = "idle";
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
                // Absent-key and empty-string converge on the same render
                // path (the glyph fallback), which is exactly why an item
                // cached before this quick task needs no migration and no
                // cache invalidation — it just reads as image-less until
                // the next refresh fills it in.
                revalidated.push({
                    title: it.title,
                    link: it.link,
                    dateMs: typeof it.dateMs === "number" ? it.dateMs : 0,
                    source: typeof it.source === "string" ? it.source : "",
                    image: typeof it.image === "string" && it.image.indexOf(root.allowedScheme) === 0 ? it.image : ""
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

    // ══════════════════════════════════════════════════════════════════
    // ── In-shell source editor (quick task 260819-pi3) ───────────────────
    // Everything below stays ABOVE the two FileViews per this file's own
    // load-bearing declaration-order rule (see header).
    // ══════════════════════════════════════════════════════════════════

    // D-4 — data-hygiene bound on operator-authored names. Layout is
    // bounded SEPARATELY, in pixels, in NewsPane.qml — a character count
    // cannot guarantee pixel width because Design.qml deliberately pins
    // no font family (the shell inherits the GTK font from gsettings).
    readonly property int maxSourceNameLen: 32

    // The editor's model — a readonly COMPUTED property for the same
    // reason `sources` above is one: it can never hold a stale `onLoaded`
    // snapshot. `root.sources` is enabled-and-valid-only and projects
    // away `enabled`, so it cannot drive an editor that must show
    // disabled rows too (anchor 4).
    readonly property var allSources: root._allSources()

    // D-6 — set by addSource()/setSourceEnabled(true); consumed by the
    // sources-changed handler below, which Qt.callLater()s the actual
    // refresh so it reads settled state rather than the pre-write
    // snapshot.
    property bool _refreshWhenSourcesSettle: false

    // ── D-5 — the probe register, a SEPARATE register from the run's own
    //    counters on purpose: sharing requestsInFlight would let a
    //    completing probe fire _finishRun() and publish a half-built
    //    run. probeState is one of "idle" | "probing" | "ok" | "failed".
    property string probeState: "idle"
    property string probeReason: ""
    property string probeDetail: ""
    property string probeUrl: ""
    property string probeTitle: ""
    property int probeItemCount: 0

    // The editor's model. Duck-typed on `.length` per anchor 5 — never
    // the native array-type predicate against anything reached through
    // newsState (see `_validSources()`'s own LIVE-MEASURED FINDING
    // above). Does NOT filter on scheme or on empty name — a malformed
    // entry must stay visible so the operator can delete it. `index` is
    // carried for logging only; every mutator below keys on `url` (D-2),
    // never on index, because a splice shifts every later index.
    function _allSources() {
        var raw = newsState.sources;
        var out = [];
        if (!raw || typeof raw.length !== "number") {
            console.log("NewsBackend: _allSources() — news-sources.json 'sources' has no usable length — treating as empty");
            return out;
        }
        for (var i = 0; i < raw.length; i++) {
            var s = raw[i];
            if (!s || typeof s !== "object") {
                console.log("NewsBackend: _allSources() — source[" + i + "] skipped, not an object");
                continue;
            }
            out.push({
                name: typeof s.name === "string" ? s.name : "",
                url: typeof s.url === "string" ? s.url : "",
                enabled: s.enabled !== false,
                index: i
            });
        }
        return out;
    }

    // Strips control characters (everything below U+0020, plus U+007F),
    // collapses whitespace to a single space, trims. Returns "" for a
    // non-string.
    function _normaliseName(raw) {
        if (typeof raw !== "string")
            return "";
        var out = "";
        for (var i = 0; i < raw.length; i++) {
            var code = raw.charCodeAt(i);
            if (code < 0x20 || code === 0x7f)
                continue;
            out += raw[i];
        }
        return out.replace(/\s+/g, " ").trim();
    }

    // The add-flow's name fallback when a feed carries no usable title:
    // strip allowedScheme, cut at the first "/", drop a ":port", drop a
    // leading "www.". Returns "" if nothing usable is left.
    function _hostnameOf(url) {
        if (typeof url !== "string" || url.indexOf(root.allowedScheme) !== 0)
            return "";
        var rest = url.slice(root.allowedScheme.length);
        var slashIdx = rest.indexOf("/");
        if (slashIdx !== -1)
            rest = rest.slice(0, slashIdx);
        var colonIdx = rest.indexOf(":");
        if (colonIdx !== -1)
            rest = rest.slice(0, colonIdx);
        if (rest.indexOf("www.") === 0)
            rest = rest.slice(4);
        return rest;
    }

    // The ONE write path for the source array (anchor 2's idiom, exactly
    // as setViewMode() above already proves). Deliberately NOT a
    // whole-object republish, for the same reason setViewMode() gives:
    // `sources` is not a native JS Array on this Qt build, so a generic
    // re-serialise risks clobbering the operator's list. setViewMode()
    // itself is left alone — it mutates a top-level key, not the array —
    // two callers, same refuse-on-malformed guard, no shared mode flag.
    function _writeSources(mutator) {
        try {
            var raw = sourcesFile.text();
            var parsed = JSON.parse(raw);
            if (!parsed || typeof parsed !== "object" || !parsed.sources || typeof parsed.sources.length !== "number") {
                console.log("NewsBackend: _writeSources() refused — news-sources.json has no usable 'sources' length");
                return false;
            }
            var ok = mutator(parsed.sources);
            if (ok === false) {
                console.log("NewsBackend: _writeSources() refused by mutator — nothing written");
                return false;
            }
            sourcesFile.setText(JSON.stringify(parsed, null, 2));
            return true;
        } catch (e) {
            console.log("NewsBackend: _writeSources() failed: " + e);
            return false;
        }
    }

    // Linear scan comparing arr[i].url === url exactly. Duck-typed
    // length again (anchor 5).
    function _findSourceIndex(arr, url) {
        if (!arr || typeof arr.length !== "number")
            return -1;
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] && arr[i].url === url)
                return i;
        }
        return -1;
    }

    // Drops every cached item belonging to `name`. Assigns root.items in
    // ONE statement — never incrementally (see _finishRun()'s own
    // comment on this discipline).
    function _pruneItemsOfSource(name) {
        var kept = root.items.filter(function (i) {
            return i.source !== name;
        });
        if (kept.length !== root.items.length) {
            root.items = kept;
            root.writeCache();
        }
    }

    // Rewrites `source` on every cached item matching oldName. Note:
    // `_failedNames` may still hold the old name for the remainder of
    // the current run, which only means carry-forward in _finishRun()
    // matches nothing for that one run — harmless, self-correcting on
    // the next refresh.
    function _renameItemsOfSource(oldName, newName) {
        var renamed = root.items.map(function (i) {
            if (i.source === oldName)
                return Object.assign({}, i, {
                    source: newName
                });
            return i;
        });
        root.items = renamed;
        root.writeCache();
    }

    // Returns "" when acceptable, else a reason code. ownUrl is the
    // entry's own url ("" for the add flow) — excluded from the
    // duplicate-name scan so renaming a source to its own current name
    // (case-adjusted) is not rejected as a duplicate of itself.
    // Case-insensitive: the filter compares names exactly, so two names
    // differing only in case would be technically distinct and visually
    // indistinguishable.
    function validateName(name, ownUrl) {
        var norm = root._normaliseName(name);
        if (norm === "")
            return "empty-name";
        if (norm.length > root.maxSourceNameLen)
            return "long-name";
        var all = root._allSources();
        var lower = norm.toLowerCase();
        for (var i = 0; i < all.length; i++) {
            if (all[i].url !== ownUrl && all[i].name.toLowerCase() === lower)
                return "duplicate-name";
        }
        return "";
    }

    // → "ok" or a reason code. Live probe happens in NewsPane.qml via
    // probeSource() (Task 2) BEFORE this is ever called — this is the
    // commit step, and it re-validates regardless so the UI is never the
    // only thing standing between a bad entry and the file.
    function addSource(url, name) {
        var trimmedUrl = typeof url === "string" ? url.trim() : "";
        if (trimmedUrl.indexOf(root.allowedScheme) !== 0) {
            console.log("NewsBackend: addSource() rejected — url is not " + root.allowedScheme);
            return "scheme";
        }
        if (root._findSourceIndex(root._allSources(), trimmedUrl) !== -1) {
            console.log("NewsBackend: addSource() rejected — duplicate url " + trimmedUrl);
            return "duplicate-url";
        }
        if (root._allSources().length >= root.maxSources) {
            console.log("NewsBackend: addSource() rejected — " + root.maxSources + "-source cap reached");
            return "full";
        }
        var nameCode = root.validateName(name, "");
        if (nameCode !== "") {
            console.log("NewsBackend: addSource() rejected — " + nameCode);
            return nameCode;
        }
        var normName = root._normaliseName(name);
        var wrote = root._writeSources(function (arr) {
            arr.push({
                name: normName,
                url: trimmedUrl,
                enabled: true
            });
            return true;
        });
        if (!wrote) {
            console.log("NewsBackend: addSource() write failed for " + trimmedUrl);
            return "write-failed";
        }
        root._refreshWhenSourcesSettle = true;
        return "ok";
    }

    // → "ok", "not-found" or "write-failed". This is what stops the
    // filter stranding on a source that no longer exists and stops the
    // list showing headlines from a source the dropdown no longer lists.
    function removeSource(url) {
        var all = root._allSources();
        var idx = root._findSourceIndex(all, url);
        if (idx === -1) {
            console.log("NewsBackend: removeSource() — url not found: " + url);
            return "not-found";
        }
        var name = all[idx].name;
        var wrote = root._writeSources(function (arr) {
            var i = root._findSourceIndex(arr, url);
            if (i === -1)
                return false;
            arr.splice(i, 1);
            return true;
        });
        if (!wrote) {
            console.log("NewsBackend: removeSource() write failed for " + url);
            return "write-failed";
        }
        if (root.selectedSource === name)
            root.selectedSource = "";
        root._pruneItemsOfSource(name);
        return "ok";
    }

    // → "ok" or a reason code. Moves the filter and the already-fetched
    // headlines with the rename when the currently filtered source is
    // the one being renamed, so the filter is never stranded.
    function renameSource(url, name) {
        var code = root.validateName(name, url);
        if (code !== "") {
            console.log("NewsBackend: renameSource() rejected — " + code);
            return code;
        }
        var all = root._allSources();
        var idx = root._findSourceIndex(all, url);
        if (idx === -1) {
            console.log("NewsBackend: renameSource() — url not found: " + url);
            return "not-found";
        }
        var oldName = all[idx].name;
        var normName = root._normaliseName(name);
        var wrote = root._writeSources(function (arr) {
            var i = root._findSourceIndex(arr, url);
            if (i === -1)
                return false;
            arr[i].name = normName;
            return true;
        });
        if (!wrote) {
            console.log("NewsBackend: renameSource() write failed for " + url);
            return "write-failed";
        }
        if (root.selectedSource === oldName)
            root.selectedSource = normName;
        root._renameItemsOfSource(oldName, normName);
        return "ok";
    }

    // → "ok", "not-found" or "write-failed". Disabling resets the filter
    // and drops that source's headlines (same anti-stranding rule as
    // removeSource()); enabling defers a refresh (D-6). No confirm on
    // either direction — disable is reversible.
    function setSourceEnabled(url, on) {
        var all = root._allSources();
        var idx = root._findSourceIndex(all, url);
        if (idx === -1) {
            console.log("NewsBackend: setSourceEnabled() — url not found: " + url);
            return "not-found";
        }
        var name = all[idx].name;
        var wrote = root._writeSources(function (arr) {
            var i = root._findSourceIndex(arr, url);
            if (i === -1)
                return false;
            arr[i].enabled = !!on;
            return true;
        });
        if (!wrote) {
            console.log("NewsBackend: setSourceEnabled() write failed for " + url);
            return "write-failed";
        }
        if (!on) {
            if (root.selectedSource === name)
                root.selectedSource = "";
            root._pruneItemsOfSource(name);
        } else {
            root._refreshWhenSourcesSettle = true;
        }
        return "ok";
    }

    // For an `rss` or `rdf:RDF` document element, walk channel then title
    // — RSS 1.0 puts <channel> at the top level exactly as RSS 2.0 does,
    // so the two share this branch; only <item> placement differs between
    // them, and that is _parseFeed()'s concern, not this function's. For a
    // `feed` document element, walk title directly. Reuses
    // _childrenNamed()/_textOf() — the same DOM helpers _parseFeed()
    // itself uses. Runs the result through _normaliseName() and
    // truncates to maxSourceNameLen. Returns "" when there is nothing
    // usable (the add-flow then falls back to _hostnameOf()).
    function _feedTitleOf(doc) {
        if (!doc || !doc.documentElement)
            return "";
        var docEl = doc.documentElement;
        var titleNode = null;
        if (docEl.nodeName === "rss" || root._isRdfRoot(docEl.nodeName)) {
            var channels = root._childrenNamed(docEl, "channel");
            if (channels.length > 0) {
                var channelTitles = root._childrenNamed(channels[0], "title");
                if (channelTitles.length > 0)
                    titleNode = channelTitles[0];
            }
        } else if (docEl.nodeName === "feed") {
            var feedTitles = root._childrenNamed(docEl, "title");
            if (feedTitles.length > 0)
                titleNode = feedTitles[0];
        }
        if (!titleNode)
            return "";
        var normalised = root._normaliseName(root._textOf(titleNode));
        return normalised.length > root.maxSourceNameLen ? normalised.slice(0, root.maxSourceNameLen) : normalised;
    }

    // ── D-5 — the probe is a second CALLER of the shared transport, not
    //    a second fetcher. Never touches requestsInFlight, sourcesOk,
    //    sourcesFailed, lastError or _runBuffer — see the probe
    //    register's own comment for why. Carries the D-32 gate: zero
    //    network activity while the centre is closed, the same guard
    //    refresh() carries. ────────────────────────────────────────────
    function probeSource(url) {
        var trimmed = typeof url === "string" ? url.trim() : "";
        root.probeTitle = "";
        root.probeItemCount = 0;
        root.probeDetail = "";
        root.probeUrl = trimmed;

        if (!root.centreOpen) {
            console.log("NewsBackend: probeSource() refused — centre closed");
            root.probeState = "failed";
            root.probeReason = "centre-closed";
            return;
        }
        if (root.probeState === "probing") {
            console.log("NewsBackend: probeSource() ignored — a probe is already in flight");
            return;
        }
        if (trimmed.indexOf(root.allowedScheme) !== 0) {
            console.log("NewsBackend: probeSource() rejected — url is not " + root.allowedScheme);
            root.probeState = "failed";
            root.probeReason = "scheme";
            return;
        }
        if (root._findSourceIndex(root._allSources(), trimmed) !== -1) {
            console.log("NewsBackend: probeSource() rejected — duplicate url " + trimmed);
            root.probeState = "failed";
            root.probeReason = "duplicate-url";
            return;
        }
        if (root._allSources().length >= root.maxSources) {
            console.log("NewsBackend: probeSource() rejected — " + root.maxSources + "-source cap reached");
            root.probeState = "failed";
            root.probeReason = "full";
            return;
        }

        root.probeState = "probing";
        root.probeReason = "";
        root._fetchXml(trimmed, function (result) {
            // Discard a superseded/aborted probe — the guard that makes
            // a late DONE a no-op. abort() resets probeState to "idle"
            // on centre-close; a text-field edit or a fresh probeSource()
            // call moves probeUrl on before this callback ever fires.
            if (root.probeState !== "probing" || root.probeUrl !== trimmed) {
                console.log("NewsBackend: probeSource() callback discarded — superseded or aborted");
                return;
            }
            if (!result.ok) {
                root.probeState = "failed";
                root.probeReason = result.reason;
                root.probeDetail = result.detail;
                console.log("NewsBackend: probeSource(" + trimmed + ") failed — " + result.reason);
                return;
            }
            var doc = result.doc;
            // ── Two distinct failures, deliberately NOT one. This branch
            //    used to answer "not-a-feed" for both, and a LIVE OPERATOR
            //    TEST proved that conflation actively misleads: probing
            //    slashdot.org/slashdot.rdf reports the URL is not a feed,
            //    when in truth it 301s through a cleartext http:// hop and
            //    Qt is left holding the HTML redirect page — nothing was
            //    ever parsed, and the real feed at rss.slashdot.org is
            //    perfectly readable. Measured through qml6 with this
            //    file's own userAgent: content-type HTML, responseXML
            //    null. Splitting them is the same discipline that already
            //    separates "not a feed" from "parsed but empty".
            if (!doc || !doc.documentElement) {
                root.probeState = "failed";
                root.probeReason = "not-xml";
                console.log("NewsBackend: probeSource(" + trimmed + ") failed — response carried no parseable XML document (a redirect to an HTML page does this)");
                return;
            }
            // A real XML document whose root is simply not one this shell
            // reads. The accepted roots must stay in lockstep with
            // _parseFeed()'s own branches, or the probe would green-light
            // a document that the feed parser then returns zero items for.
            var probeRoot = doc.documentElement.nodeName;
            if (probeRoot !== "rss" && probeRoot !== "feed" && !root._isRdfRoot(probeRoot)) {
                root.probeState = "failed";
                root.probeReason = "not-a-feed";
                root.probeDetail = probeRoot;
                console.log("NewsBackend: probeSource(" + trimmed + ") failed — XML parsed but root <" + probeRoot + "> is not a readable RSS, Atom or RDF feed");
                return;
            }
            var title = root._feedTitleOf(doc);
            var fallbackName = title !== "" ? title : root._hostnameOf(trimmed);
            try {
                var parsed = root._parseFeed(doc, fallbackName);
                if (parsed.length === 0) {
                    root.probeState = "failed";
                    root.probeReason = "no-items";
                    console.log("NewsBackend: probeSource(" + trimmed + ") failed — feed parsed but carried no usable headlines");
                    return;
                }
                root.probeTitle = fallbackName;
                root.probeItemCount = parsed.length;
                root.probeState = "ok";
            } catch (e) {
                root.probeState = "failed";
                root.probeReason = "parse";
                console.log("NewsBackend: probeSource(" + trimmed + ") — parse threw: " + e);
            }
        });
    }

    // Resets the whole probe register to idle. Called by the pane when
    // the URL text changes or the add flow is cancelled — a stale "ok"
    // must never be committable against a URL the operator has since
    // edited.
    function clearProbe() {
        root.probeState = "idle";
        root.probeReason = "";
        root.probeDetail = "";
        root.probeUrl = "";
        root.probeTitle = "";
        root.probeItemCount = 0;
    }

    // D-6 — the same deferral onCentreOpenChanged already uses, for the
    // identical reason: refresh() reads root.sources, which derives from
    // the child JsonAdapter (newsState). Reading it straight after
    // setText() would read the pre-write value (the "child's binding
    // lags the parent's own signal" class this file's onCentreOpenChanged
    // comment documents, quick task 260819-426). So: set a flag here, and
    // let this handler — the change signal of the readonly computed
    // `sources` property, which the file already relies on re-deriving
    // correctly — consume the flag and Qt.callLater() the refresh.
    onSourcesChanged: {
        if (root._refreshWhenSourcesSettle) {
            root._refreshWhenSourcesSettle = false;
            Qt.callLater(function () {
                root.refresh(true);
            });
        }
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
            property string view_mode: "compact"
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
