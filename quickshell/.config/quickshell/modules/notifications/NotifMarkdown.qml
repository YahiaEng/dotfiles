// NotifMarkdown.qml — the allowlist filter for sender-supplied notification
// body text (Phase 19 Plan 04, Task 2, QNOTIF-04/05, T-19-10).
//
// RESEARCH.md's own "Don't Hand-Roll" table names the shape this file
// implements: not a CommonMark parser (Qt's `Text.MarkdownText` already IS
// one), but a pre-processing FILTER that escapes every CommonMark-special
// character by default, then re-permits exactly three constructs — bold
// (`**text**`), italic (`*text*`) and links (`[text](url)`) — by finding
// them via regex and re-inserting their own delimiters unescaped, with
// their OWN inner text/url independently escaped so nothing nested can
// smuggle a fourth construct back in through a link's own label or a
// bold span's own contents.
//
// T-19-10's mitigation is this file's whole reason to exist: any markup
// construct the allowlist does not explicitly name (headings, code
// fences/spans, images, raw HTML tags, blockquotes, horizontal rules,
// lists) renders as LITERAL escaped text once handed to
// `Text.MarkdownText`, never as the construct itself. Escape-everything-
// then-allowlist is the opposite of the usual denylist instinct, and that
// inversion is the actual security property — a denylist can always miss
// a construct nobody thought to name; an allowlist cannot.
//
// A `!` immediately before a link pattern is an IMAGE construct
// (`![alt](url)`), not a link — CommonMark's own grammar. The combined
// regex below matches that shape FIRST and explicitly escapes it whole,
// rather than letting the link branch match only the trailing
// `[alt](url)` portion and leave a real, unintended link behind with a
// stray literal `!` in front of it.
//
// Only `http://`/`https://` URLs are re-permitted as real links — a
// `javascript:`/`file:`/`data:` URL (or any other scheme) falls through
// to the escape branch and renders as literal text instead of becoming a
// clickable link, closing the obvious injection vector a markdown-link
// allowlist alone would otherwise open.
pragma Singleton
import QtQml

QtObject {
    id: root

    // CommonMark's own backslash-escapable ASCII punctuation set — every
    // character in this class becomes inert (`\x` renders as literal `x`)
    // once handed to `Text.MarkdownText`. Escaping `<`/`>` is what keeps a
    // raw HTML tag (`<script>`) from ever being interpreted as inline
    // HTML; escaping `` ` `` closes both code spans and code fences;
    // escaping `#`/`-`/`+`/`.`/`!`/`>` closes headings, lists, blockquotes
    // and images at the point CommonMark would otherwise recognise them.
    function _escapeLiteral(text) {
        return text.replace(/[\\`*_{}\[\]()#+\-.!><|~^$%&]/g, function (c) {
            return "\\" + c;
        });
    }

    // Combined, ordered alternation — checked left-to-right at every
    // starting position, so an image (`!` + link shape) is claimed by
    // group 1 before the plain-link branch (group 2) ever gets a chance
    // to match only its trailing `[text](url)` portion. Bold's `\*\*`
    // alternative is listed before italic's single `\*` for the same
    // reason: at a position with two literal asterisks, the engine tries
    // the two-asterisk alternative first.
    readonly property var _pattern: /(!\[[^\[\]]*\]\([^()\s]*\))|(\[([^\[\]]*)\]\(([^()\s]+)\))|(\*\*([^*]+)\*\*)|(\*([^*]+)\*)/

    // The one public verb. Never returns anything that was not already
    // present in `raw` — every character of the output is either an
    // escaped copy of `raw`'s own text or one of the three re-permitted
    // delimiter pairs wrapping escaped inner content.
    function filter(raw) {
        if (!raw || raw.length === 0)
            return "";

        var result = "";
        var remaining = raw;

        while (remaining.length > 0) {
            var m = root._pattern.exec(remaining);
            if (!m) {
                result += root._escapeLiteral(remaining);
                break;
            }

            // Everything before the match renders literally.
            result += root._escapeLiteral(remaining.slice(0, m.index));

            if (m[1] !== undefined) {
                // Image construct — disallowed outright, whole token
                // escaped so `!`, `[`, `]`, `(`, `)` all render literal.
                result += root._escapeLiteral(m[1]);
            } else if (m[2] !== undefined) {
                // Link — only http(s) URLs are re-permitted as real
                // links; anything else falls back to literal escaping.
                var linkText = root._escapeLiteral(m[3]);
                var url = m[4];
                if (/^https?:\/\//i.test(url)) {
                    result += "[" + linkText + "](" + url.replace(/[\\()]/g, "\\$&") + ")";
                } else {
                    result += root._escapeLiteral(m[2]);
                }
            } else if (m[5] !== undefined) {
                // Bold.
                result += "**" + root._escapeLiteral(m[6]) + "**";
            } else if (m[7] !== undefined) {
                // Italic.
                result += "*" + root._escapeLiteral(m[8]) + "*";
            }

            remaining = remaining.slice(m.index + m[0].length);
        }

        return result;
    }
}
