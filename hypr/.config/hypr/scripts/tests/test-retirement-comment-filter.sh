#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║   RETIREMENT-CHECK COMMENT-FILTER UNIT TEST           ║
# ║   (quick task 260826-npc)                             ║
# ╚══════════════════════════════════════════════════════╝
#
# Covers `comment_line_filter()` in `../retirement-check`, the predicate the
# `cross-package-refs` class uses to skip whole-line comments.
#
# WHY THIS EXISTS SEPARATELY FROM `retirement-check --self-test`:
# the self-test could not see this predicate at all. Measured during
# 260826-npc — with the predicate deliberately stubbed to `return False`,
# all five fixture trees still produced their expected verdicts. The
# fixtures prove the CLASSES fire; nothing proved the predicate's own
# boundaries. A predicate that decides what a blocking gate is allowed to
# ignore needs its own falsifiable test.
#
# THE TWO CASES THAT MATTER MOST are the negatives, not the positives:
# a CSS id selector (`#name { }`) and a line of code with a trailing
# comment must BOTH still be scanned. If either ever starts reading as a
# comment, the gate silently stops seeing real surviving references and
# goes green while the tree is dirty — the exact failure mode that makes a
# green gate worse than no gate.
#
# NO REGISTRY SURFACE NAME APPEARS IN THIS FILE, deliberately, comments
# included. `tests/` is scanned by the `test-fixtures` class WITHOUT the
# comment filter (that class is supposed to match comments), so writing a
# real surface name here — even in prose — would red-light that class for
# that surface. The placeholder `retired-thing` is in no registry, so it
# matches nothing. Keep it that way.
#
# Exit 0 all cases as expected / 1 otherwise.

set -uo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
TARGET="$SCRIPT_DIR/../retirement-check"

if [[ ! -f "$TARGET" ]]; then
    echo "[FAIL] comment-filter: cannot find retirement-check at $TARGET" >&2
    exit 1
fi

python3 - "$TARGET" <<'PYEOF'
import re
import sys

# Exec the SHIPPED definitions straight out of the gate rather than a
# retyped copy — a copy drifts, and a drifted copy tests nothing.
src = open(sys.argv[1], encoding='utf-8').read()
try:
    start = src.index('_LINE_COMMENT_RE = re.compile(')
    end = src.index('def grep_hits(')
except ValueError:
    print('[FAIL] comment-filter: could not locate the predicate in retirement-check '
          '(was it renamed? update this test with it)')
    sys.exit(1)

ns = {'re': re}
exec(src[start:end], ns)
make = ns['comment_line_filter']

# (line, is_wholly_a_comment, why)
CASES = [
    ('// the thing was retired and this explains why',   True,  'C++/QML line comment'),
    ('# the thing was retired and this explains why',    True,  'hash comment'),
    ('    // indented prose mentioning retired-thing',   True,  'indented line comment'),
    ('-- lua comment about retired-thing',               True,  'lua line comment'),
    ('--[[ lua block comment about retired-thing ]]',    True,  'lua block comment'),
    ('<!-- retired-thing lived here -->',                True,  'html comment'),
    ('/* retired-thing */',                              True,  'single-line block comment'),
    ('',                                                 False, 'empty line'),
    ('   ',                                              False, 'whitespace-only line'),
    # ── The negatives. These are the whole point. ───────────────────────
    ('#retired-thing { color: red; }',                   False, 'CSS id selector is NOT a comment'),
    ('#retired-thing',                                   False, 'bare CSS id selector'),
    ('exec-once = retired-thing  # restart it',          False, 'trailing comment, code present'),
    ('map ctrl+r launch retired-thing',                  False, 'plain config line'),
    ('prog --retired-thing-compat',                      False, 'long option is NOT a comment'),
    ('hl.exec_cmd("retired-thing") -- keep',             False, 'lua code, trailing comment'),
    ('/* retired-thing */ still_code()',                 False, 'block closes, code follows'),
]

failures = 0
for line, want, why in CASES:
    got = make()(line)
    ok = got is want
    failures += 0 if ok else 1
    print(f"  [{'PASS' if ok else 'FAIL'}] comment-filter: {why} "
          f"(want {want}, got {got})")

# A block comment spans lines: every line inside it carries no code, and the
# first line after the close does.
SPAN = [
    ('/* retired-thing was removed because', True),
    ('   nothing hosted it any more',        True),
    ('   and the panel took over */',        True),
    ('value = retired-thing',                False),
]
pred = make()
for line, want in SPAN:
    got = pred(line)
    ok = got is want
    failures += 0 if ok else 1
    print(f"  [{'PASS' if ok else 'FAIL'}] comment-filter: block span "
          f"{line.strip()[:38]!r} (want {want}, got {got})")

# An unterminated span in one file must never leak into the next: the
# predicate is built per file, so a fresh one starts outside any block.
leaked = make()('value = retired-thing')
ok = leaked is False
failures += 0 if ok else 1
print(f"  [{'PASS' if ok else 'FAIL'}] comment-filter: fresh predicate per file, "
      f"no block-span leak (want False, got {leaked})")

total = len(CASES) + len(SPAN) + 1
print('')
print(f'Comment-filter summary: {total - failures} passed, {failures} failed')
sys.exit(1 if failures else 0)
PYEOF
