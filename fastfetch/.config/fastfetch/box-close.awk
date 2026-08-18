#!/usr/bin/env gawk -f
# fastfetch/box-close.awk — post-filter that closes the box (quick task
# 260818-srl, M-2/M-3).
#
# fastfetch has no value-width padding (`--key-width`/`--key-padding-left`
# pad KEYS only, measured live this session — a `{value:20}` format
# placeholder is silently ignored). The right border of a "closed" box can
# therefore not be drawn by fastfetch's own config; this filter appends it
# after the fact, self-calibrated off the box's own top rule so there is no
# constant shared between the matugen template and this file — the two can
# never drift apart.
#
# Design, one line at a time, no state beyond the current line and W:
#   - The first line containing BOTH "┌" and "┐" (the top rule) sets W to
#     its own SGR-stripped display width. gawk's length() under
#     LANG=en_US.UTF-8 counts CHARACTERS, not bytes (M-6, verified live) —
#     the same convention the matugen template's own width choice used, so
#     the two stay self-consistent even for any future double-width glyph
#     row (an accepted pre-existing characteristic of this convention, not
#     introduced here).
#   - Every line containing "│" (content or a side rule) is closed: take
#     the substring from the FIRST "│" onward, strip SGR into a scratch
#     copy, pad with spaces to W-1 display columns, append "│".
#   - The appended border is coloured by CAPTURE, not by a hardcoded
#     constant: the SGR sequence immediately preceding that first "│" is
#     re-emitted before the appended "│", then reset. This filter never
#     learns a palette value — it cannot drift from whatever the template
#     coloured the line's own opening border with (the matugen template
#     sets every rule row's `outputColor` and the box interior's
#     `display.color.keys`/`output`/`separator` to the SAME `outline`/
#     content roles, so the two borders match by construction, not by
#     coincidence).
#   - Every other line (the logo — ASCII art or a kitty graphics APC
#     sequence with unicode placeholders) passes through BYTE FOR BYTE.
#     Both art forms sit strictly left of the box and never contain "│"
#     themselves (M-7: `grep -c '│' art/*.txt` is 0 across every shipped
#     art file, including this task's new arch.txt) — so this filter never
#     has to understand what a logo is, only where the box's left border
#     starts.
#   - If the padded content would be NEGATIVE width (a content row wider
#     than the box), the line is printed unmodified rather than producing
#     a ragged border, and a counter is printed to stderr once at the end
#     — a silently ragged box is worse than a loud one.

BEGIN {
    W = 0
    overflow_count = 0
}

# SGR (\033[...m) stripped into a scratch copy; caller decides what to do
# with the two variables this leaves behind: `stripped` (no ANSI at all)
# and `display_width` (its character length).
function strip_sgr(s,    stripped) {
    stripped = s
    gsub(/\033\[[0-9;]*m/, "", stripped)
    return stripped
}

# Returns the raw SGR escape sequence that ends closest to (and at or
# before) position `upto` in the ORIGINAL (unstripped) string `s` — i.e.
# the colour still in effect at that column. Empty string if none found.
function last_sgr_before(s, upto,    pos, seq, best, tail) {
    best = ""
    pos = 1
    while (match(substr(s, pos), /\033\[[0-9;]*m/)) {
        seq = substr(s, pos + RSTART - 1, RLENGTH)
        if (pos + RSTART - 1 > upto) break
        best = seq
        pos = pos + RSTART + RLENGTH - 1
    }
    return best
}

# ── Top rule: learn W once, from the FIRST line that has both corners ──
!W && index($0, "┌") && index($0, "┐") {
    corner_pos = index($0, "┌")
    W = length(strip_sgr(substr($0, corner_pos)))
}

# ── Any line carrying the box's own left border ──
index($0, "│") {
    bar_pos = index($0, "│")
    # Substring from the first │ onward, in the ORIGINAL (SGR-intact)
    # string, so the colour capture below can see what preceded it.
    before = substr($0, 1, bar_pos - 1)
    from_bar = substr($0, bar_pos)

    stripped = strip_sgr(from_bar)
    content_width = length(stripped)

    if (W > 0 && content_width > W - 1) {
        # Row wider than the box — print unmodified, count it, never
        # produce a ragged pad.
        overflow_count++
        print $0
        next
    }

    pad = ""
    if (W > 0) {
        for (i = content_width; i < W - 1; i++) pad = pad " "
    }

    colour = last_sgr_before($0, bar_pos)

    # `from_bar` (NOT `stripped`) is what gets printed here — it carries
    # every internal SGR transition fastfetch itself emitted (the key in
    # one colour, the value in another, per display.color.keys/output).
    # `stripped`/`content_width` above exist ONLY to measure the pad
    # amount; printing the stripped copy would flatten the whole row to
    # one colour, which is not this filter's job.
    print before from_bar pad colour "│" "\033[m"
    next
}

# ── Everything else (the logo, or a pre-box line) — byte for byte ──
{
    print $0
}

END {
    if (overflow_count > 0) {
        printf "box-close.awk: %d row(s) wider than the box — printed unmodified, not padded\n", overflow_count > "/dev/stderr"
    }
}
