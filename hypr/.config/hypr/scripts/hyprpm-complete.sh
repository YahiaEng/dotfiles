#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║        HYPRPM DYNAMIC-CURSORS COMPLETION (D-33)       ║
# ║   Post-login half of the optional dynamic-cursors     ║
# ║   plugin build. Finishes what install.sh's guarded    ║
# ║   hyprpm block could not — hyprpm needs a live         ║
# ║   compositor session (to build headers against the    ║
# ║   exact running Hyprland commit) and root, and         ║
# ║   install.sh frequently runs from a TTY with no         ║
# ║   compositor at all. Contract: takes no arguments,      ║
# ║   never blocks login, never prompts, ALWAYS exits 0.    ║
# ╚══════════════════════════════════════════════════════╝
#
# Pitfall 4 (17-RESEARCH.md, live-verified): issuing the raw
# `hyprctl plugin load <path>` IPC call against an already-loaded plugin
# TIMES OUT ("Hyprland IPC didn't respond in time"), even though the
# plugin and compositor remain healthy afterward. This script therefore
# NEVER issues that raw load call — `hyprpm reload` is the only load
# trigger it is permitted to use; its own stated purpose is "ensure all
# enabled plugins are loaded", i.e. it is idempotent by design.
#
# Pitfall 5 (17-RESEARCH.md): hyprpm pins each build to a hash of the
# Hyprland commit plus five library versions. Any `pacman -Syu` that
# touches hyprland silently stops the plugin loading — expected behaviour
# after a system update, not a regression — with the failure visible only
# in the compositor's own log unless something compares the recorded hash
# against the live commit and surfaces it. That comparison lives below.
#
# Privilege discipline (T-17-06/T-17-10): this script never widens sudo
# scope — no policy file, no NOPASSWD rule, no caller-supplied path or
# URL (it takes no arguments at all). When cached credentials are
# unavailable it notifies with the exact remedy and stops; it never
# prompts and never retries.
#
# [Rule 1 fix, found live during Task 3's fault injection] `hyprpm
# reload` (and, once credentials succeed, `hyprpm update`'s own implicit
# load step) signals the LIVE compositor to load the plugin. On this
# machine `ecosystem.enforce_permissions = true` (enabled Phase 16,
# hypr/.config/hypr/config/permissions.lua) and no `plugin`-type grant
# existed for hyprpm — every hyprpm call that reaches the compositor's
# load path popped a REAL GUI `hyprland-dialog` ("...trying to load a
# plugin... Allow/Deny") and BLOCKED THE PROCESS until a human clicked
# it, live-reproduced: a bare `hyprpm reload` hung past a 120s bound with
# no default action. This directly threatens this script's own "never
# blocks" contract, so every hyprpm call below is now `timeout`-bounded —
# belt-and-suspenders alongside the proper systemic fix (a `plugin`-type
# grant for /usr/bin/hyprpm added to permissions.lua, matching
# Hyprland's own shipped example verbatim: `/usr/share/hypr/hyprland.lua`
# line 78 carries this exact commented-out line). That grant requires a
# Hyprland restart to take effect (permissions.lua's own documented
# restart-not-reload rule) — the timeout bound is what protects every
# login before that restart happens, and remains as defense in depth
# afterward.
#
# [Rule 2 fix, found live during Phase 17 plan 05, Task 1] `hyprctl
# plugin list | grep dynamic-cursors` is not the whole story any more.
# 17-05 added a guarded Lua config module
# (hypr/.config/hypr/config/dynamic-cursors.lua, D-35/D-36/D-37) that
# applies the plugin's shake-to-find-off and mode config ONLY on a config
# pass where the plugin is ALREADY loaded (upstream's mandatory
# `if hl.plugin.dynamic_cursors then ... end` guard). That module's OWN
# `hl.plugin.load()` call runs once, synchronously, at Hyprland's initial
# config pass — BEFORE this script (an async, backgrounded autostart
# entry) has had any chance to run. So on a completely normal login, by
# the time this script's own `hyprpm reload` below actually loads the
# plugin, Hyprland's Lua config has already finished its one pass with
# the plugin not yet loaded, and dynamic-cursors.lua's config block never
# ran. Without a follow-up compositor config reload, shake-to-find would
# silently stay on upstream's default (ON) forever, defeating D-36's
# entire purpose with nothing failing loudly anywhere — live-verified via
# 17-05's nested-harness testing (17-05-SUMMARY.md has the full evidence
# trail, including that `hl.plugin.load()` itself does not functionally
# load the plugin on this installed Hyprland 0.56.2 build under any
# tested call shape — this follow-up reload is what makes D-36/D-37
# actually take effect regardless, via the SAME hyprpm-driven load this
# script already performs). Fired only when this script's own load call
# just changed the plugin's state from not-loaded to loaded — never on
# the already-loaded hot path above, which must stay a fast no-op.

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    # No session, no work — the same headless-guard shape every
    # session-scoped listener in this repo uses (check the signature is
    # set before touching a socket path built from it). Silent: a
    # login-time helper with no session to act on has nothing worth
    # reporting.
    exit 0
fi

# Corroborate the signature actually resolves to a live compositor socket
# — the same two-step (signature-set, then socket-exists) discipline
# every session-scoped listener in this repo applies before trusting a
# socket path built from it. A bogus or stale HYPRLAND_INSTANCE_SIGNATURE
# must be treated exactly like no session at all — NOT as "plugin not
# loaded", which would send this script down the sudo-gated rebuild path
# against a compositor that was never actually reachable.
SOCKET_PATH="${XDG_RUNTIME_DIR:-}/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock"
if [[ -z "${XDG_RUNTIME_DIR:-}" || ! -S "$SOCKET_PATH" ]]; then
    exit 0
fi

USER_NAME="${USER:-$(id -un)}"
STATE_DIR="/var/cache/hyprpm/$USER_NAME"
ARTIFACT="$STATE_DIR/dynamic-cursors/dynamic-cursors.so"
STATE_TOML="$STATE_DIR/state.toml"
HYPRPM_PLUGIN_URL="https://github.com/virtcode/hypr-dynamic-cursors"

# Guard the notification itself so a missing notification daemon can
# never make this script fail.
_notify() {
    command -v notify-send &>/dev/null && notify-send "Dynamic cursors" "$1" 2>/dev/null
    return 0
}

# Sudo-gated (re)build path, shared by the "not built" and "stale ABI"
# branches below. Never prompts: gated on a non-interactive credential
# check. On success, runs the same three guarded hyprpm steps install.sh
# uses (register if not already registered, enable, update), then
# hyprpm reload — every step `|| true`-guarded so nothing here can ever
# propagate a nonzero exit. On failure, notifies with the exact remedy
# command and stops; never retries.
_rebuild() {
    if sudo -n true 2>/dev/null; then
        if ! hyprpm list 2>/dev/null | grep -q 'dynamic-cursors'; then
            timeout 30 hyprpm add "$HYPRPM_PLUGIN_URL" || true
        fi
        timeout 15 hyprpm enable dynamic-cursors || true
        timeout 180 hyprpm update || true
        timeout 20 hyprpm reload || true
        # Rule 2 fix (see header) — give dynamic-cursors.lua's guarded
        # config block a config pass where the plugin is now loaded.
        if hyprctl plugin list 2>/dev/null | grep -q 'dynamic-cursors'; then
            timeout 10 hyprctl reload &>/dev/null || true
        fi
    else
        _notify "Optional dynamic-cursors plugin needs a rebuild — run: hyprpm update && hyprpm reload"
    fi
    return 0
}

# 1. Already loaded — the hot path. This is the branch every normal login
#    after the first successful build takes, and it must never issue the
#    raw load IPC (Pitfall 4) — just check and exit.
if hyprctl plugin list 2>/dev/null | grep -q 'dynamic-cursors'; then
    exit 0
fi

# 2. Not built. install.sh's guarded block never ran to completion (no
#    session at install time, or credentials were unavailable then too).
if [[ ! -f "$ARTIFACT" ]]; then
    _rebuild
    exit 0
fi

# 3. Built but not loaded — check the ABI before reloading (Pitfall 5).
#    The state-store hash format, read live, is the Hyprland commit
#    followed by five library versions joined by underscores. Only the
#    leading commit field is compared — that is what a Hyprland upgrade
#    changes; the full five-library hash is deliberately not
#    reconstructed here.
recorded_hash=$(grep -m1 '^hash' "$STATE_TOML" 2>/dev/null | sed -E "s/^hash = '([^_]+)_.*/\1/")
live_commit=$(hyprctl version -j 2>/dev/null | jq -r '.commit // empty' 2>/dev/null)

if [[ -n "$recorded_hash" && -n "$live_commit" && "$recorded_hash" == "$live_commit" ]]; then
    # ABI matches — safe to reload. hyprpm reload's own "Headers outdated"
    # refusal is the backstop for the rarer library-only bump this leading
    # -commit comparison cannot see; catch that refusal and turn it into
    # the same remedy notification rather than failing silently.
    reload_out=$(timeout 20 hyprpm reload 2>&1) || true
    if printf '%s\n' "$reload_out" | grep -qiE 'outdated|mismatch'; then
        _notify "Dynamic cursors headers outdated — run: hyprpm update && hyprpm reload"
    elif hyprctl plugin list 2>/dev/null | grep -q 'dynamic-cursors'; then
        # Rule 2 fix (see header) — give dynamic-cursors.lua's guarded
        # config block a config pass where the plugin is now loaded.
        timeout 10 hyprctl reload &>/dev/null || true
    fi
else
    # ABI mismatch (or undeterminable) — the build is stale after a
    # Hyprland upgrade. Same sudo-gated rebuild path as "not built".
    _rebuild
fi

exit 0
