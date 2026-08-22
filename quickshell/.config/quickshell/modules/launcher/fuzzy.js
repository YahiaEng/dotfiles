.pragma library

// fuzzy.js — vendored fuzzy-subsequence matcher (quick task 260822-sht,
// Task 2). Both reference shells vendor one for this exact purpose
// (Caelestia: fzf.js/fuzzysort.js inside utils/Searcher.qml; end-4:
// Fuzzy.go() with a Levenshtein fallback inside AppSearch.qml) — this file
// follows the same practice but is written fresh rather than copied from
// either, since neither's exact source ships in this repo or is reachable
// offline, and the underlying algorithm (in-order subsequence match with
// positional bonuses) is standard, small, and easy to verify by reading
// this file top to bottom.
//
// `.pragma library` makes this a stateless JS module: a single shared
// instance across every `import "fuzzy.js" as Fuzzy"` in the launcher
// package, holding no per-caller state — exactly what a pure scoring
// function needs, and the standard QML idiom for a vendored algorithm file
// (no QML type, so it needs no `qmldir` entry — only `.qml` types require
// that; see this directory's `qmldir` header).

// score(needle, haystack) — case-insensitive in-order subsequence match.
// Returns -1 when `needle`'s characters do NOT all appear, in order, in
// `haystack`. Otherwise returns a non-negative integer where HIGHER means
// a BETTER match, built from three bonuses on top of one point per
// matched character:
//   - +8  the match starts at haystack's very first character
//   - +4  the match immediately follows a word-boundary separator
//         (space/-/_/.) or a lower→upper camelCase transition
//   - +2 * run-length  for each character that continues an unbroken run
//         of consecutive matched characters (rewards "typed contiguously"
//         over "scattered across the string")
// A small length penalty is subtracted at the end so that, between two
// equally-good subsequence matches, the shorter haystack (a tighter,
// less "buried" match) ranks first.
//
// An empty `needle` always matches with score 0 — callers are expected to
// skip fuzzy scoring entirely for an empty query (Launcher.qml's own
// `q === ""` fast path does this), but this keeps the function total
// rather than throwing on an input a caller technically could pass.
function score(needle, haystack) {
    if (!needle || needle.length === 0)
        return 0;
    if (!haystack || haystack.length === 0)
        return -1;

    const n = needle.toLowerCase();
    const h = haystack.toLowerCase();

    let total = 0;
    let searchFrom = 0;
    let consecutive = 0;

    for (let i = 0; i < n.length; i++) {
        const needleChar = n[i];
        const foundAt = h.indexOf(needleChar, searchFrom);
        if (foundAt === -1)
            return -1;

        let charScore = 1;

        if (foundAt === 0) {
            charScore += 8;
        } else {
            const prevRaw = haystack[foundAt - 1];
            const curRaw = haystack[foundAt];
            const isSeparatorBoundary = prevRaw === " " || prevRaw === "-" || prevRaw === "_" || prevRaw === ".";
            const isCamelBoundary = !isSeparatorBoundary && prevRaw === prevRaw.toLowerCase() && curRaw === curRaw.toUpperCase() && curRaw !== curRaw.toLowerCase();
            if (isSeparatorBoundary || isCamelBoundary)
                charScore += 4;
        }

        if (foundAt === searchFrom) {
            consecutive += 1;
            charScore += consecutive * 2;
        } else {
            consecutive = 0;
        }

        total += charScore;
        searchFrom = foundAt + 1;
    }

    total -= Math.floor(haystack.length / 8);

    return total;
}
