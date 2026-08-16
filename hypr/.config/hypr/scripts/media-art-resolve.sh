#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║       MEDIA ART RESOLVER (BAR-04 / D-21, T-08-07-03/04) ║
# ║  HARD CONSTRAINT: $1 is UNTRUSTED third-party D-Bus     ║
# ║  data (mpris:artUrl). It is NEVER re-parsed as code —   ║
# ║  no eval, no `sh -c`, no string-built shell command.    ║
# ║  Prints a local, image-verified file path on stdout and ║
# ║  exits 0, or prints NOTHING and exits non-zero.         ║
# ╚══════════════════════════════════════════════════════╝
#
# CLI: media-art-resolve.sh <artUrl>
#
# Scheme allowlist is the single most important guard in this file
# (T-08-07-03/04): only file:// / http:// / https:// are accepted, and
# the http(s) branch pre-flight-rejects loopback/RFC1918 hosts before
# any network call — see the Security Domain section of 08-RESEARCH.md.

set -euo pipefail

# Renamed from the retired widget daemon's own cache-naming convention —
# RETIRE-07, Phase 20 Plan 10, that daemon is uninstalled; this script's
# own consumer has always owned the cache.
CACHE_DIR="$HOME/.cache/media-art"
MAX_BYTES=5000000
TIMEOUT_SECS=5

# ── 1. Arity + charset guard ─────────────────────────────────────────
url="${1-}"
if [[ $# -ne 1 || -z "$url" ]]; then
    exit 2
fi
if [[ ${#url} -gt 2048 ]]; then
    exit 2
fi
# Reject any C0 control character or newline embedded in the argument.
# Bracket-expression test only — never a subshell/eval re-parse of $url.
if [[ "$url" == *$'\n'* ]]; then
    exit 2
fi
if LC_ALL=C grep -qP '[\x00-\x1f]' <<<"$url" 2>/dev/null; then
    exit 2
fi

# ── 2. Scheme allowlist (T-08-07-03/04) — bash pattern match, no subshell.
case "$url" in
    file://*)
        scheme="file"
        ;;
    http://*)
        scheme="http"
        ;;
    https://*)
        scheme="https"
        ;;
    *)
        # ftp / data / gopher / javascript / bare path / scheme with
        # embedded whitespace — everything else. No filesystem or
        # network side effect happens before this point.
        exit 3
        ;;
esac

# ── 3. Cache dir — refuse to follow a symlink or a non-directory path.
if [[ -e "$CACHE_DIR" && ! -d "$CACHE_DIR" ]]; then
    exit 4
fi
if [[ -L "$CACHE_DIR" ]]; then
    exit 4
fi
mkdir -p "$CACHE_DIR"
chmod 700 "$CACHE_DIR"

_is_image() {
    # $1: path to sniff. Requires a `image/*` mime type from file(1)'s
    # own content sniffing — never trusts an extension.
    local path="$1"
    local mime
    mime="$(file --mime-type -b -- "$path" 2>/dev/null || true)"
    [[ "$mime" == image/* ]]
}

if [[ "$scheme" == "file" ]]; then
    # ── 4. file:// branch (the verified Zen/Firefox case) ────────────
    stripped_path="${url#file://}"
    # Percent-decode %XX sequences without ever re-parsing the result
    # as code: printf '%b' on a %->\x substitution is pure data
    # transformation, not execution.
    decoded="${stripped_path//%/\\x}"
    decoded="$(printf '%b' "$decoded" 2>/dev/null || true)"
    if [[ -z "$decoded" ]]; then
        exit 5
    fi

    canon=""
    if canon="$(realpath -e -- "$decoded" 2>/dev/null)"; then
        :
    else
        exit 5
    fi

    if [[ ! -f "$canon" || ! -r "$canon" ]]; then
        exit 5
    fi
    if ! _is_image "$canon"; then
        exit 5
    fi

    printf '%s\n' "$canon"
    exit 0
fi

# ── 5. http(s):// branch (Spotify, Assumption A2) ────────────────────
# Cache key: sha256 of the FULL url — never player-supplied, never
# predictable from track metadata (T-08-07-05).
url_hash="$(sha256sum <<<"$url" | awk '{print $1}')"
cache_path="$CACHE_DIR/$url_hash"

# Best-effort SSRF guard (syntactic only, not DNS-rebinding-proof —
# documented residual risk, T-08-07-04): reject the obvious internal
# targets by extracting the host portion via bash parameter expansion.
#
# CR-01: the host extraction and denylist below must survive the literal
# encodings a hostile mpris:artUrl can use to smuggle an internal target
# past a naive dotted-decimal denylist:
#   http://[::1]/         -> IPv6 bracket literal (a bare `%%:*` cut would
#                            truncate the address to "[" and never match)
#   http://2130706433/    -> bare-integer form of 127.0.0.1
#   http://[fd00::1]/     -> IPv6 unique-local (fc00::/7)
#   https://0x7f.0.0.1/   -> hex-encoded loopback octet
# The posture is allowlist-the-shapes-we-can-reason-about, deny the rest:
# a normal DNS name or a range-checked dotted-decimal IPv4 is allowed;
# every other numeric/hex/bracketed encoding is refused.
host_port="${url#*://}"
host_port="${host_port%%/*}"

# Strip an [IPv6] bracket literal to its inner address WITHOUT cutting at
# the first colon (which would truncate a `[::1]` host to "["). Otherwise
# strip a trailing :port from an ordinary host.
if [[ "$host_port" == \[*\]* ]]; then
    host="${host_port#\[}"
    host="${host%%\]*}"
    is_ipv6_literal=1
else
    host="${host_port%%:*}"
    is_ipv6_literal=0
fi
# Lowercase for consistent hex / IPv6 hextet comparisons.
host="${host,,}"

case "$host" in
    localhost | 0.0.0.0)
        exit 3
        ;;
    # IPv4 dotted-decimal internal ranges.
    127.* | 10.* | 192.168.* | 169.254.*)
        exit 3
        ;;
    172.1[6-9].* | 172.2[0-9].* | 172.3[01].*)
        exit 3
        ;;
    # IPv6: loopback (::1), IPv4-mapped loopback (::ffff:127.*),
    # unique-local fc00::/7 (first hextet fc../fd..), link-local fe80::/10
    # (first hextet fe8./fe9./fea./feb.). Host here always contains a ':'
    # for these, so an ordinary (colon-free) DNS name can never match.
    ::1 | ::ffff:127.* | fc*:* | fd*:* | fe8*:* | fe9*:* | fea*:* | feb*:*)
        exit 3
        ;;
esac

# Non-bracketed hosts only: reject numeric/hex IPv4 encodings that dodge
# the dotted-decimal denylist above. Bracketed literals were already
# range-matched (and public IPv6 is intentionally allowed).
if [[ "$is_ipv6_literal" -eq 0 ]]; then
    # 0x / hex-encoded octet(s) — e.g. 0x7f.0.0.1, 0x7f000001, 0.0x7f.0.1.
    case "$host" in
        0x* | *.0x*)
            exit 3
            ;;
    esac
    # A host with no ASCII letter is a numeric IP form. The only numeric
    # shape trusted is a dotted-decimal quad with four in-range, non-octal
    # octets; every other numeric encoding (bare integer like 2130706433,
    # octal-looking octets, short forms) is refused.
    if [[ "$host" != *[a-z]* ]]; then
        if [[ "$host" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
            octet_o1="${BASH_REMATCH[1]}"
            octet_o2="${BASH_REMATCH[2]}"
            octet_o3="${BASH_REMATCH[3]}"
            octet_o4="${BASH_REMATCH[4]}"
            for octet in "$octet_o1" "$octet_o2" "$octet_o3" "$octet_o4"; do
                # Leading-zero octet = octal-looking -> refuse.
                if [[ "$octet" != "0" && "$octet" == 0* ]]; then
                    exit 3
                fi
                if (( 10#$octet > 255 )); then
                    exit 3
                fi
            done
        else
            exit 3
        fi
    fi
fi

# Cache hit: an existing regular file (never a symlink — unlink and
# treat as a miss) that still passes the image mime gate.
if [[ -e "$cache_path" ]]; then
    if [[ -L "$cache_path" ]]; then
        rm -f -- "$cache_path"
    elif [[ -f "$cache_path" ]] && _is_image "$cache_path"; then
        printf '%s\n' "$cache_path"
        exit 0
    else
        rm -f -- "$cache_path"
    fi
fi

# Cache miss: download into a mktemp file INSIDE the cache dir so the
# final `mv` is same-filesystem-atomic. Trap-clean on any exit path.
tmp_file="$(mktemp "$CACHE_DIR/.dl.XXXXXX")"
cleanup() {
    rm -f -- "$tmp_file"
}
trap cleanup EXIT

# The `--` guard before the url is mandatory: it stops a url beginning
# with a dash from being read as a curl flag (T-08-07-04).
if ! curl -sfL --no-netrc --proto '=http,https' --proto-redir '=http,https' \
    --max-time "$TIMEOUT_SECS" --max-filesize "$MAX_BYTES" \
    -o "$tmp_file" -- "$url" 2>/dev/null; then
    exit 6
fi

if ! _is_image "$tmp_file"; then
    # Non-image response body never enters the cache.
    exit 7
fi

chmod 600 "$tmp_file"
mv -- "$tmp_file" "$cache_path"
trap - EXIT

printf '%s\n' "$cache_path"
exit 0
