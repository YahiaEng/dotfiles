// SaverArt.qml — the wordmark source shared by all four screensaver
// styles (quick task 260827-b52 Task 2, ruling D6: "read
// ~/.config/aorus/branding/screensaver.txt if present, else built-in").
//
// ── Two FileViews, one resolution point ──────────────────────────────
// `overrideFile` is the operator's branding file and is EXPECTED to be
// absent — a missing file is the default state on a fresh install, not
// an error, so its `onLoadFailed` clears the text and says nothing (the
// same shape `Prefs.qml:532` uses for a never-persisted prefs.json).
// `builtinFile` reads the wordmark shipped in this repo and IS an error
// if missing, because stow put it there.
//
// `rows` resolves ONCE here, and every style reads `rows`/`cols`/
// `rowCount` off this one object. A style must never read either
// FileView directly — that is what keeps the override rule in one place
// instead of four.
//
// ── watchChanges: true, deliberately ──────────────────────────────────
// Editing the branding file should be visible the next time the saver
// appears without a shell restart. This is the opposite call to
// Prefs.qml's `watchChanges: false`, and for a different reason: prefs
// are written BY the shell (a watch would re-read its own write), while
// this file is only ever written by the operator or the transcoder
// script. MEMORY live-shell-ignores-disk-state-edits is about the false
// case; this is the true case, on purpose.
//
// ── Trailing-space padding is load-bearing ────────────────────────────
// `cols` is the width of the WIDEST row, and every row is padded to it
// on read. SaverConstellation maps cell coordinates to screen positions
// by dividing by `cols - 1`, so a short row would silently shift its
// glyphs left. The shipped asset is already padded; a hand-edited
// override may not be.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // The operator's file, if it exists and parses to at least one
    // non-blank line; otherwise the shipped wordmark. Never empty: an
    // empty `rows` would leave every style rendering nothing, which on a
    // full-screen black surface is indistinguishable from a crash.
    readonly property var rows: {
        const o = root._split(root._overrideText);
        if (o.length > 0)
            return o;
        const b = root._split(root._builtinText);
        if (b.length > 0)
            return b;
        return ["AORUS"];
    }

    readonly property int rowCount: root.rows.length
    readonly property int cols: {
        var w = 1;
        for (var i = 0; i < root.rows.length; i++)
            w = Math.max(w, root.rows[i].length);
        return w;
    }

    // Whether the operator's branding file is the one being rendered —
    // surfaced so the settings page can say so rather than leaving the
    // operator guessing why their file did not take.
    readonly property bool usingOverride: root._split(root._overrideText).length > 0

    readonly property string overridePath: Quickshell.env("HOME") + "/.config/aorus/branding/screensaver.txt"

    // ── The one place in this shell that pins a font family ─────────────
    // `Design.qml:127` states, at length, that font FAMILY is deliberately
    // not a token: every Text inherits the GTK font so `font-switcher.sh`
    // re-fonts the shell in the same stroke it re-fonts GTK apps. That
    // decision is correct and is NOT overturned here — which is exactly
    // why this lives in this module rather than becoming a Design token.
    //
    // The wordmark is half-block art on a fixed character grid. A
    // proportional family does not render it wrong so much as destroy it:
    // column N of row 1 stops sitting above column N of row 2, and the
    // letterforms shear apart. The art is not text that happens to be
    // monospaced, it is a bitmap whose pixels are characters — so the
    // grid is a correctness requirement, not a style preference.
    //
    // A CHAIN, resolved HERE rather than handed to Qt. FiraCode Nerd Font
    // Mono is what the shipped wordmark was rendered in and what this host
    // has, but install.sh does not install it — `noto-fonts` is what a
    // fresh Arch install gets, and Noto Sans Mono is the reason this chain
    // ends where it does. All three fallbacks were verified to cover the
    // exact three glyphs the shipped wordmark uses (U+2580 ▀, U+2584 ▄,
    // U+2588 █) and every glyph in `scrambleGlyphs` below, so a fresh
    // install renders this correctly with no new package.
    //
    // ── Why this is resolved by hand and not by `font.families` ────────
    // The first draft of this file wrote `font.families: [...]`, the Qt
    // list form. That is NOT a property of QML's font value type on this
    // Qt (6.11.2): `QQuickFontValueType` in
    // /usr/lib/qt6/qml/QtQuick/plugins.qmltypes declares `family`,
    // singular, and no `families` — so every Text carrying it failed with
    // "Cannot assign to non-existent property families" and the whole
    // shell config refused to load. Caught by the hot-reload line in
    // ~/.cache/quickshell.log, which is the only instrument here that
    // sees this class at all: colour-lint, motion-lint, qml-import-check
    // and settings-index-check were all green across the same files, and
    // neither qmllint nor qmlformat functions on this host (both were
    // tested against a deliberately-broken file and reported nothing).
    //
    // `Qt.fontFamilies()` is the supported way to ask what is installed.
    // It is called once, in a readonly binding, so the cost is paid at
    // first use rather than per Text.
    readonly property var fontChain: ["FiraCode Nerd Font Mono", "Noto Sans Mono", "DejaVu Sans Mono", "monospace"]

    readonly property string fontFamily: {
        var have = Qt.fontFamilies();
        for (var i = 0; i < root.fontChain.length; i++) {
            if (have.indexOf(root.fontChain[i]) !== -1)
                return root.fontChain[i];
        }
        // Nothing in the chain is installed. "monospace" is not a real
        // family name to Qt either, but it is the string fontconfig
        // resolves, and a wrong monospace beats a proportional default —
        // the art needs the grid far more than it needs a specific face.
        return "monospace";
    }

    // S1's pre-reveal noise. Drawn entirely from Block Elements
    // (U+2580–U+259F) — the same Unicode block the wordmark itself lives
    // in, so anything that can render the art can render the scramble.
    // A set drawn from Braille or box-drawing would have needed its own
    // coverage proof on every fallback in the chain.
    readonly property string scrambleGlyphs: "▁▂▃▄▅▆▇█▏▎▍▌▋▊▉░▒▓▔▕▖▗▘▙▚▛▜▝▞▟"

    property string _overrideText: ""
    property string _builtinText: ""

    // Drops blank lines at both ends, keeps interior blanks (a wordmark
    // may legitimately contain an empty row), then pads every row to the
    // widest one. Returns [] for text that is entirely whitespace.
    function _split(text) {
        if (!text)
            return [];
        var lines = text.replace(/\r/g, "").split("\n");
        var first = 0;
        var last = lines.length - 1;
        while (first <= last && lines[first].trim() === "")
            first++;
        while (last >= first && lines[last].trim() === "")
            last--;
        if (last < first)
            return [];
        var out = [];
        var w = 1;
        for (var i = first; i <= last; i++) {
            out.push(lines[i]);
            w = Math.max(w, lines[i].length);
        }
        for (var j = 0; j < out.length; j++) {
            while (out[j].length < w)
                out[j] += " ";
        }
        return out;
    }

    property var _overrideFile: FileView {
        path: root.overridePath
        watchChanges: true
        // false, NOT true: an absent branding file is the default state
        // on every fresh install. Printing an error for it every shell
        // start would train the reader to ignore this file's errors.
        printErrors: false
        onLoaded: root._overrideText = text()
        onLoadFailed: root._overrideText = ""
        onFileChanged: reload()
    }

    property var _builtinFile: FileView {
        path: Qt.resolvedUrl("../../assets/wordmark.txt").toString().replace("file://", "")
        watchChanges: false
        printErrors: true
        onLoaded: root._builtinText = text()
        onLoadFailed: error => {
            // Genuinely wrong: stow ships this file. The `rows` fallback
            // above keeps the saver rendering a plain "AORUS" rather than
            // an empty screen, but the state is worth saying out loud.
            console.warn("SaverArt: built-in wordmark unreadable (" + error + ") — falling back to plain text");
            root._builtinText = "";
        }
    }
}
