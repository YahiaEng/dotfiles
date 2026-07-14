#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║       MEDIA HARDENING ADVERSARIAL GATE (BAR-04)         ║
# ║  Hermetic, rerunnable checker attacking media-*.sh with ║
# ║  hostile mpris metadata: shell metacharacters, command  ║
# ║  substitution, artUrl scheme/path abuse, Pango markup,  ║
# ║  newlines, hostile bus-name ids. Asserts nothing         ║
# ║  executes and nothing escapes its output context.       ║
# ╚══════════════════════════════════════════════════════╝
#
# Report-only — never mutates the real ~/.cache/eww-media-player or
# ~/.cache/eww-media-art. HOME is pointed at an isolated temp dir for
# the entire run, which both media-players.sh and media-art-resolve.sh
# derive their state/cache paths from.
#
# Intentionally NOT `set -e`: the scripts under test are expected to
# exit nonzero in most of these cases, and this checker must keep
# running afterward to assert on that exit code (see 08-07-PLAN.md).
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SCRIPTS_DIR="$(cd -- "$SCRIPT_DIR/.." &>/dev/null && pwd)"
MEDIA_ART_RESOLVE="$SCRIPTS_DIR/media-art-resolve.sh"
MEDIA_PLAYERS="$SCRIPTS_DIR/media-players.sh"
MEDIA_STATUS="$SCRIPTS_DIR/media-status.sh"

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

# ── Hermetic shims (playerctl, curl) + isolated HOME ────────────────
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
PLAYERCTL_LOG="$SHIMDIR/playerctl.log"
CURL_LOG="$SHIMDIR/curl.log"
: > "$PLAYERCTL_LOG"
: > "$CURL_LOG"

# A real, minimal, valid 1x1 PNG (base64) — the fake curl "downloads"
# this so the resolver's mime-gate genuinely passes on a successful
# fetch, exactly like a real image response would.
PNG_B64='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='

cat > "$SHIMDIR/playerctl" <<SHIM
#!/usr/bin/env bash
# Test shim: entirely env-var driven so each check can script a
# distinct adversarial fixture without a real player running.
: "\${PLAYERCTL_LOG:?PLAYERCTL_LOG not set}"
printf '%s\n' "\$*" >> "\$PLAYERCTL_LOG"

if [[ "\${1:-}" == "-l" || "\${1:-}" == "--list-all" ]]; then
    if [[ -n "\${FAKE_PLAYERCTL_LIST+x}" && -n "\${FAKE_PLAYERCTL_LIST}" ]]; then
        printf '%s\n' "\$FAKE_PLAYERCTL_LIST"
    fi
    exit 0
fi

player=""
rest=()
for a in "\$@"; do
    case "\$a" in
        --player=*) player="\${a#--player=}" ;;
        *) rest+=("\$a") ;;
    esac
done

case "\${rest[0]:-}" in
    status)
        printf '%s' "\${FAKE_STATUS:-Playing}"
        ;;
    metadata)
        case "\${rest[1]:-}" in
            xesam:title) printf '%s' "\${FAKE_TITLE:-}" ;;
            xesam:artist) printf '%s' "\${FAKE_ARTIST:-}" ;;
            xesam:album) printf '%s' "\${FAKE_ALBUM:-}" ;;
            mpris:artUrl) printf '%s' "\${FAKE_ARTURL:-}" ;;
            mpris:length) printf '%s' "\${FAKE_LENGTH:-0}" ;;
        esac
        ;;
    position)
        if [[ -z "\${rest[1]:-}" ]]; then
            printf '%s' "\${FAKE_POSITION:-0}"
        fi
        ;;
    volume)
        if [[ -z "\${rest[1]:-}" ]]; then
            printf '%s' "\${FAKE_VOLUME:--1}"
        fi
        ;;
    *) : ;;
esac
exit 0
SHIM
chmod +x "$SHIMDIR/playerctl"

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
export PLAYERCTL_LOG CURL_LOG

echo "test-media-hardening — adversarial gate for media-*.sh (BAR-04)"

# ── Check 1/2/3: hostile title/artist through media-status.sh once ──
echo ""
echo "-- media-status.sh once: hostile metadata --"

FAKE_PLAYERCTL_LIST="spotify"
FAKE_STATUS="Playing"
FAKE_TITLE='Evil $(id) `id` ; id & <b>x</b>'
FAKE_ARTIST=$'line-one\nline-two-after-newline'
FAKE_ALBUM="Album"
FAKE_ARTURL=""
FAKE_LENGTH="180000000"
FAKE_POSITION="10.5"
FAKE_VOLUME="0.5"
export FAKE_PLAYERCTL_LIST FAKE_STATUS FAKE_TITLE FAKE_ARTIST FAKE_ALBUM FAKE_ARTURL FAKE_LENGTH FAKE_POSITION FAKE_VOLUME

once_out="$("$MEDIA_STATUS" once 2>&1)"
rc=$?
ok=1
[[ $rc -eq 0 ]] && echo "$once_out" | jq -e . >/dev/null 2>&1 && ok=0
check "media-status.sh once: output is valid JSON" "$ok"

ok=1
title_field="$(printf '%s' "$once_out" | jq -r '.title // ""' 2>/dev/null || true)"
[[ "$title_field" == *'$(id)'* ]] && ok=0
check "media-status.sh once: .title retains literal command-substitution text" "$ok"

ok=1
printf '%s' "$once_out" | grep -q 'uid=' && ok=1 || ok=0
check "media-status.sh once: no uid= substring anywhere in output (nothing executed)" "$ok"

ok=1
lines="$(printf '%s' "$once_out" | grep -c '^{' || true)"
[[ "$lines" -eq 1 ]] && ok=0
check "media-status.sh once: emits exactly 1 JSON line despite newline-bearing artist" "$ok"

# ── Check 4: hostile id excluded from list ───────────────────────────
echo ""
echo "-- media-players.sh list: hostile id allowlist --"

FAKE_PLAYERCTL_LIST=$'spotify\nspotify; id'
export FAKE_PLAYERCTL_LIST
list_out="$("$MEDIA_PLAYERS" list 2>&1)"
ok=1
echo "$list_out" | jq -e '.[] | select(.id == "spotify")' >/dev/null 2>&1 && ok=0
check "media-players.sh list: includes valid id 'spotify'" "$ok"

ok=1
echo "$list_out" | jq -e --arg h 'spotify; id' '.[] | select(.id == $h)' >/dev/null 2>&1 || ok=0
check "media-players.sh list: excludes hostile id 'spotify; id'" "$ok"

# ── Check 5: hostile id rejected by cmd, playerctl never invoked with it
echo ""
echo "-- media-players.sh cmd: hostile id / verb / arg rejection --"

: > "$PLAYERCTL_LOG"
"$MEDIA_PLAYERS" cmd 'spotify; id' play-pause >/dev/null 2>&1
rc=$?
ok=1
[[ $rc -ne 0 ]] && ok=0
check "cmd 'spotify; id' play-pause: exits non-zero" "$ok"

if grep -q 'spotify; id' "$PLAYERCTL_LOG"; then
    ok=1
else
    ok=0
fi
check "cmd 'spotify; id' play-pause: fake playerctl never invoked with that id" "$ok"

# ── Check 6: verb outside the allowlist ─────────────────────────────
"$MEDIA_PLAYERS" cmd spotify rm-rf >/dev/null 2>&1
rc=$?
ok=1
[[ $rc -ne 0 ]] && ok=0
check "cmd spotify rm-rf: exits non-zero (verb outside allowlist)" "$ok"

# ── Check 7: non-numeric seek arg ───────────────────────────────────
"$MEDIA_PLAYERS" cmd spotify seek 'x; id' >/dev/null 2>&1
rc=$?
ok=1
[[ $rc -ne 0 ]] && ok=0
check "cmd spotify seek 'x; id': exits non-zero (non-numeric arg rejected)" "$ok"

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

# ── Check 11: no players at all -> D-25's empty-payload/exit-1 gate ─
echo ""
echo "-- D-25: zero-player gate --"

unset FAKE_PLAYERCTL_LIST
export FAKE_PLAYERCTL_LIST=""
"$MEDIA_PLAYERS" active >/dev/null 2>&1
rc=$?
ok=1
[[ $rc -ne 0 ]] && ok=0
check "media-players.sh active: exits 1 with no players (D-25 gate)" "$ok"

empty_out="$("$MEDIA_STATUS" once 2>&1)"
ok=1
empty_player="$(printf '%s' "$empty_out" | jq -r '.player // "MISSING"' 2>/dev/null || true)"
empty_volume="$(printf '%s' "$empty_out" | jq -r '.volume // "MISSING"' 2>/dev/null || true)"
[[ "$empty_player" == "" && "$empty_volume" == "-1" ]] && ok=0
check "media-status.sh once: emits the empty payload with no players (D-25)" "$ok"

echo ""
echo "Summary: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
exit $?
