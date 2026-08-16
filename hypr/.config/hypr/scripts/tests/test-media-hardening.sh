#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║       MEDIA HARDENING ADVERSARIAL GATE (BAR-04)         ║
# ║  Hermetic, rerunnable checker attacking the RETAINED     ║
# ║  album-art resolver with hostile artUrl schemes/hosts/   ║
# ║  encodings. Asserts nothing executes and nothing escapes ║
# ║  its output context, and that no network call is ever    ║
# ║  attempted before the host guard clears a URL.            ║
# ╚══════════════════════════════════════════════════════╝
#
# RETIRE-06 (Phase 21 Plan 08) trim: checks 1-7 and 11 exercised the
# retired GTK4 media applet's own two reader scripts, deleted in this same
# commit. Checks 8, 9, 9b and 10 are
# KEPT intact and unmodified — they are live network-forgery protection
# for media-art-resolve.sh, which still runs on every non-local album-art
# fetch (MediaBackend.qml builds its path by string concatenation and
# invokes it directly). Numbering intentionally NOT renumbered, so the
# surviving coverage's identity in the pre-trim test stays traceable — see
# 21-08-SUMMARY.md for the full before/after check mapping.
#
# Report-only — never mutates the real ~/.cache/media-art. HOME is pointed
# at an isolated temp dir for the entire run, which media-art-resolve.sh
# derives its cache paths from.
#
# Intentionally NOT `set -e`: the script under test is expected to exit
# nonzero in most of these cases, and this checker must keep running
# afterward to assert on that exit code (see 08-07-PLAN.md).
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SCRIPTS_DIR="$(cd -- "$SCRIPT_DIR/.." &>/dev/null && pwd)"
MEDIA_ART_RESOLVE="$SCRIPTS_DIR/media-art-resolve.sh"

PASS=0
FAIL=0

check() {
    local desc="$1"
    local ok="$2"
    if [[ "$ok" == "0" ]]; then
        echo "  [PASS] $desc"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $desc"
        FAIL=$((FAIL + 1))
    fi
}

# ── Hermetic shim (curl) + isolated HOME ────────────────────────────
SHIMDIR="$(mktemp -d)"
TMPHOME="$(mktemp -d)"
TMP_DIRS=("$SHIMDIR" "$TMPHOME")

cleanup() {
    local t
    for t in "${TMP_DIRS[@]}"; do
        rm -rf "$t"
    done
}
trap cleanup EXIT

mkdir -p "$TMPHOME/.cache"
CURL_LOG="$SHIMDIR/curl.log"
: > "$CURL_LOG"

# A real, minimal, valid 1x1 PNG (base64) — the fake curl "downloads"
# this so the resolver's mime-gate genuinely passes on a successful
# fetch, exactly like a real image response would.
PNG_B64='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='

cat > "$SHIMDIR/curl" <<SHIM
#!/usr/bin/env bash
# Test shim: logs full argv (proving/disproving whether a network call
# was ever attempted) then writes a real, valid 1x1 PNG to the -o
# target and exits 0 — a genuine successful-fetch simulation, so the
# resolver's own mime-gate and hash-key logic run for real.
: "\${CURL_LOG:?CURL_LOG not set}"
printf '%s\n' "\$*" >> "\$CURL_LOG"

out=""
prev=""
for a in "\$@"; do
    if [[ "\$prev" == "-o" ]]; then
        out="\$a"
    fi
    prev="\$a"
done

if [[ -n "\$out" ]]; then
    printf '%s' "$PNG_B64" | base64 -d > "\$out"
fi
exit 0
SHIM
chmod +x "$SHIMDIR/curl"

export PATH="$SHIMDIR:$PATH"
export HOME="$TMPHOME"
export CURL_LOG

echo "test-media-hardening — adversarial gate for media-art-resolve.sh (BAR-04)"

# ── Check 8: ftp artUrl — rejected, zero network calls ──────────────
echo ""
echo "-- media-art-resolve.sh: artUrl scheme/host adversarial gate --"

: > "$CURL_LOG"
"$MEDIA_ART_RESOLVE" 'ftp://evil/x.png' >/dev/null 2>&1
rc=$?
ok=1
[[ $rc -ne 0 ]] && ok=0
check "media-art-resolve.sh ftp://: exits non-zero" "$ok"

ok=1
[[ ! -s "$CURL_LOG" ]] && ok=0
check "media-art-resolve.sh ftp://: curl never invoked" "$ok"

# ── Check 9: loopback http host — rejected before any network call ──
: > "$CURL_LOG"
"$MEDIA_ART_RESOLVE" 'http://127.0.0.1/x.png' >/dev/null 2>&1
rc=$?
ok=1
[[ $rc -ne 0 ]] && ok=0
check "media-art-resolve.sh http://127.0.0.1: exits non-zero" "$ok"

ok=1
[[ ! -s "$CURL_LOG" ]] && ok=0
check "media-art-resolve.sh http://127.0.0.1: host guard fires before any network call" "$ok"

# ── Check 9b (CR-01): literal-encoding SSRF bypasses of the loopback/
# internal denylist — each hostile URL must be blocked BEFORE any fetch.
# IPv6-bracket loopback/unique-local, decimal-integer IP, and hex-encoded
# loopback all previously slipped past the naive `%%:*` host extraction.
CR01_BYPASSES=(
    'http://[::1]/x.png'          # IPv6 loopback via bracket literal
    'http://[fd00::1]/x.png'      # IPv6 unique-local (fc00::/7)
    'http://2130706433/x.png'     # decimal-integer form of 127.0.0.1
    'https://0x7f.0.0.1/x.png'    # hex-encoded loopback octet
    'http://[::ffff:127.0.0.1]/x.png'  # IPv4-mapped loopback
)
for bypass in "${CR01_BYPASSES[@]}"; do
    : > "$CURL_LOG"
    "$MEDIA_ART_RESOLVE" "$bypass" >/dev/null 2>&1
    rc=$?
    ok=1
    [[ $rc -ne 0 ]] && ok=0
    check "media-art-resolve.sh $bypass: exits non-zero (SSRF bypass blocked)" "$ok"

    ok=1
    [[ ! -s "$CURL_LOG" ]] && ok=0
    check "media-art-resolve.sh $bypass: host guard fires before any network call" "$ok"
done

# ── Check 10: two distinct https artUrls -> two distinct cache files
: > "$CURL_LOG"
out_a="$("$MEDIA_ART_RESOLVE" 'https://example.invalid/a.png' 2>/dev/null || true)"
out_b="$("$MEDIA_ART_RESOLVE" 'https://example.invalid/b.png' 2>/dev/null || true)"
ok=1
if [[ -n "$out_a" && -n "$out_b" && "$out_a" != "$out_b" ]]; then
    ok=0
fi
check "media-art-resolve.sh: two distinct https urls -> two distinct cache paths" "$ok"

ok=1
if [[ -n "$out_a" && -n "$out_b" ]]; then
    base_a="$(basename -- "$out_a")"
    base_b="$(basename -- "$out_b")"
    if [[ "$base_a" != *"a.png"* && "$base_a" != *"example.invalid"* \
        && "$base_b" != *"b.png"* && "$base_b" != *"example.invalid"* ]]; then
        ok=0
    fi
fi
check "media-art-resolve.sh: neither cache filename contains a substring of its url" "$ok"

ok=1
[[ -f "$out_a" ]] && [[ -f "$out_b" ]] && ok=0
check "media-art-resolve.sh: both resolved cache files actually exist on disk" "$ok"

echo ""
echo "Summary: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
exit $?
