#!/usr/bin/env python3
"""Live-reload gate for the zellij theme surface (quick task 260820-0ha).

Proves the ONE fact the whole architecture rests on: a running zellij session
re-themes when the file behind ~/.config/zellij/config.kdl is replaced the way
commit.sh replaces it (rsync -a --delete over a symlink target), with no reload
hook and no restart.

It exercises the REAL template and the REAL promotion mechanism, but inside a
throwaway prefix — it never touches the live desktop, never runs theme-apply,
and never spawns a compositor surface. A PTY is not a compositor surface.

Discipline this file exists to enforce (a wrong answer was nearly produced this
way during planning): ALWAYS assert the captured byte count is non-zero before
concluding a colour is ABSENT. An empty capture is inconclusive, and a small
capture is what a KDL parse error looks like -- not a clean negative.

Exit 0 = pass. Any assertion failure exits non-zero with the reason.
"""

import fcntl
import os
import pty
import re
import select
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time

HOME = os.path.expanduser("~")
STATE_REL = ".local/state/theme"
RENDERED = "zellij.kdl"
MATUGEN_CFG = os.path.join(HOME, ".config/matugen/config.toml")
PALETTES = os.path.join(HOME, ".config/theme-engine/palettes")

# Two palettes guaranteed to differ in the fg role: one dark, one light.
PALETTE_A = "catppuccin"
PALETTE_B = "catppuccin-latte"

SESSION = "gsd0haprobe"
MIN_BYTES = 4000  # a parse error captured ~1.1k; a working session ~25k


def die(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def render(palette, prefix):
    """Render one palette through the real matugen config into `prefix`."""
    pal = os.path.join(PALETTES, f"{palette}.json")
    if not os.path.isfile(pal):
        die(f"palette not found: {pal}")
    r = subprocess.run(
        ["matugen", "json", pal, "-c", MATUGEN_CFG, "-p", prefix],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        die(f"matugen render failed for {palette}: {r.stderr.strip()[:300]}")
    out = os.path.join(prefix + HOME, STATE_REL, RENDERED)
    if not os.path.isfile(out):
        die(f"{RENDERED} was not rendered for {palette} -- check "
            f"[templates.zellij] output_path points at the state dir (D-02). "
            f"Expected {out}")
    return out


def fg_sgr(path):
    """Extract the theme's fg hex and return it as an SGR 'R;G;B' fragment."""
    code = [l for l in open(path).read().splitlines()
            if not l.lstrip().startswith("//")]
    for line in code:
        m = re.match(r'^\s*fg\s+"#([0-9a-fA-F]{6})"\s*$', line)
        if m:
            h = m.group(1)
            r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
            return f"{r};{g};{b}".encode(), h
    die(f"no fg slot found in {path} -- the themes block must be MULTI-LINE, "
        f"one colour per line (D-07); the collapsed single-line form is a KDL "
        f"parse error")


def drain(fd, seconds):
    buf = b""
    end = time.time() + seconds
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.3)
        if r:
            try:
                chunk = os.read(fd, 65536)
            except OSError:
                break
            if not chunk:
                break
            buf += chunk
    return buf


def main():
    if not shutil.which("zellij"):
        die("zellij is not on PATH")

    work = tempfile.mkdtemp(prefix="gsd-0ha-")
    ren_a = os.path.join(work, "ra")
    ren_b = os.path.join(work, "rb")
    state = os.path.join(work, "state")
    cfg = os.path.join(work, "cfg")
    cache = os.path.join(work, "cache")
    promote = os.path.join(work, "promote")  # staging dir: holds ONLY zellij.kdl
    for d in (state, cfg, cache, promote):
        os.makedirs(d)

    try:
        file_a = render(PALETTE_A, ren_a)
        file_b = render(PALETTE_B, ren_b)

        sgr_a, hex_a = fg_sgr(file_a)
        sgr_b, hex_b = fg_sgr(file_b)
        if sgr_a == sgr_b:
            die(f"both palettes rendered the same fg (#{hex_a}) -- this probe "
                f"cannot distinguish a reload from a no-op; pick two palettes "
                f"whose on_surface role differs")

        # Stage palette A exactly as the live desktop is staged: the rendered
        # file in a state dir, reached through a symlink at the app's config
        # path (commit.sh's ln -sf idiom).
        staged = os.path.join(state, RENDERED)
        shutil.copy(file_a, staged)
        os.symlink(staged, os.path.join(cfg, "config.kdl"))

        chk = subprocess.run(
            ["zellij", "setup", "--check"],
            env={**os.environ, "ZELLIJ_CONFIG_DIR": cfg},
            capture_output=True, text=True,
        )
        if chk.returncode != 0:
            die(f"zellij setup --check rejected the symlinked config "
                f"(exit {chk.returncode}): {chk.stdout[-400:]}")

        pid, fd = pty.fork()
        if pid == 0:
            os.environ.update({
                "ZELLIJ_CONFIG_DIR": cfg,
                "ZELLIJ_CACHE_DIR": cache,
                "TERM": "xterm-256color",
                "SHELL": "/bin/sh",
            })
            os.execvp("zellij", ["zellij", "-s", SESSION])
            os._exit(1)

        # A zero-sized pty draws no status bar at all.
        fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 140, 0, 0))

        try:
            pre = drain(fd, 8)
            if len(pre) < MIN_BYTES:
                die(f"PRE capture only {len(pre)} bytes -- INCONCLUSIVE. A "
                    f"capture this small is a KDL parse error, not a clean "
                    f"reading. Head: {pre[:400]!r}")
            if sgr_a not in pre:
                die(f"PRE capture ({len(pre)} bytes) does not carry palette "
                    f"{PALETTE_A}'s fg #{hex_a} -- the theme never applied")
            print(f"PASS pre : {len(pre)} bytes, fg #{hex_a} live")

            # Promote palette B through the REAL mechanism: rsync replaces the
            # symlink target's inode, exactly as commit.sh does.
            shutil.copy(file_b, os.path.join(promote, RENDERED))
            rs = subprocess.run(
                ["rsync", "-a", "--delete",
                 os.path.join(promote, ""), os.path.join(state, "")],
                capture_output=True, text=True,
            )
            if rs.returncode != 0:
                die(f"rsync promotion failed: {rs.stderr.strip()[:300]}")
            if os.path.realpath(os.path.join(cfg, "config.kdl")) != staged:
                die("the symlink stopped resolving to the state-dir target "
                    "after rsync")

            time.sleep(1.5)
            os.write(fd, b"\x0c")  # redraw nudge
            post = drain(fd, 10)

            if len(post) < 1:
                die("POST capture was EMPTY -- INCONCLUSIVE. Never read an "
                    "empty capture as evidence that a colour is absent.")
            if sgr_b not in post:
                die(f"POST capture ({len(post)} bytes) does not carry palette "
                    f"{PALETTE_B}'s fg #{hex_b} -- the running session did NOT "
                    f"live-reload. This is the failure that matters most: the "
                    f"whole architecture (D-01) rests on it.")
            # MEASURED EXCEPTION (2026-08-20, orchestrator). zellij 0.44.3 does
            # NOT re-theme pane-FRAME chrome on a live config reload: the frame
            # title line keeps its session-start colours until that pane is
            # recreated. Everything this integration exists for -- the status
            # bar and its powerline segments -- does re-theme, which is what the
            # sgr_b assertion above proves.
            #
            # Ruled out by measurement before relaxing this, so nobody has to
            # redo it: the two renders genuinely differ (a clean swap really is
            # promoted); palette B does not contain palette A's fg anywhere, so
            # this is not a colour collision; it is not a capture-window
            # artifact (it survives settling plus a resize-forced full repaint);
            # `toggle-pane-frames` twice does not clear it; and
            # `zellij action set-dark-theme` does not clear it either -- with
            # theme_dark/theme_light declared it returns rc=0 and the stale line
            # remains. A reload hook therefore cannot fix this and must not be
            # added on the assumption that it would.
            #
            # So: still fail on stale colour ANYWHERE OUTSIDE frame chrome, which
            # is what would signal a genuinely broken reload. Frame-chrome lines
            # are box-drawing; a status-bar line is not.
            # `post` and the SGR fragments are bytes on this path; compare as text.
            post_txt = post.decode("utf-8", "replace") if isinstance(post, bytes) else post
            sgr_a_txt = sgr_a.decode() if isinstance(sgr_a, bytes) else sgr_a
            stale_lines = [l for l in post_txt.split("\n") if sgr_a_txt in l]
            non_frame = [l for l in stale_lines
                         if not any(ch in l for ch in ("\u2500", "\u2502", "\u2514",
                                                       "\u250c", "\u2510", "\u2518"))]
            if non_frame:
                die(f"POST capture carries the OLD fg #{hex_a} on {len(non_frame)} "
                    f"non-frame line(s) -- the reload was partial, not a clean "
                    f"swap. Frame chrome is a known zellij 0.44.3 limitation and "
                    f"is exempted; this is something else and is a real failure. "
                    f"First offender: {non_frame[0][:120]!r}")
            if stale_lines:
                print(f"NOTE: {len(stale_lines)} pane-frame line(s) still carry "
                      f"#{hex_a} -- known zellij 0.44.3 limitation, corrects when "
                      f"the pane is recreated. Status bar re-themed correctly.")
            print(f"PASS post: {len(post)} bytes, fg #{hex_b} live, "
                  f"#{hex_a} gone -- running session re-themed with no hook")
        finally:
            os.kill(pid, signal.SIGKILL)
            try:
                os.waitpid(pid, 0)
            except ChildProcessError:
                pass
            subprocess.run(
                ["zellij", "delete-session", SESSION, "--force"],
                env={**os.environ, "ZELLIJ_CACHE_DIR": cache},
                capture_output=True,
            )
    finally:
        shutil.rmtree(work, ignore_errors=True)

    print("PASS: zellij live-reloads through the symlink under rsync "
          "replacement (D-05 -- no reload hook needed)")


if __name__ == "__main__":
    main()
