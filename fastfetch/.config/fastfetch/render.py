#!/usr/bin/env python3
"""Lay out the themed Fastfetch output using the terminal's current dimensions."""

import argparse
import fcntl
import os
from pathlib import Path
import random
import re
import shutil
import struct
import subprocess
import termios
import unicodedata


ART = Path(__file__).resolve().parent / "art"
STATE = Path.home() / ".local/state/theme"
TEXT_LOGOS = ("arch", "star", "cyberpunk_mask", "illuminati")
SPRITES = ("pulse", "sweep", "glitch", "scan", "assemble", "orbit")
SGR = re.compile(r"\x1b\[[0-9;:]*m")
SGR_PARTS = re.compile(r"(\x1b\[[0-9;:]*m)")
RULE = re.compile(r"([┌├└])─+([┐┤┘])")
TOP_RULE = re.compile(r"(?:\x1b\[[0-9;:]*m)*┌─+┐")
RESET = "\x1b[0m"


def terminal_size():
    try:
        with open("/dev/tty", "rb") as tty:
            rows, columns, width, height = struct.unpack(
                "HHHH", fcntl.ioctl(tty, termios.TIOCGWINSZ, bytes(8))
            )
    except OSError:
        return 80, 24, 0, 0
    return columns or 80, rows or 24, width, height


def cell_width(char):
    if unicodedata.category(char) in ("Mn", "Me", "Cc", "Cf"):
        return 0
    return 2 if unicodedata.east_asian_width(char) in ("W", "F") else 1


def width(line):
    return sum(map(cell_width, SGR.sub("", line)))


def fit(line, columns):
    if width(line) <= columns:
        return line
    remaining = columns - 1
    parts = []
    for part in SGR_PARTS.split(line):
        if SGR.fullmatch(part):
            parts.append(part)
            continue
        for char in part:
            remaining -= cell_width(char)
            if remaining < 0:
                return "".join(parts) + "…" + RESET
            parts.append(char)
    return "".join(parts)


def render_box(lines, columns):
    result = []
    border_color = ""
    for line in lines:
        text = SGR.sub("", line)
        rule = RULE.fullmatch(text)
        if rule:
            border_color = line[:line.index(rule[1])]
            result.append(f"{border_color}{rule[1]}{'─' * (columns - 2)}{rule[2]}{RESET}")
        elif text.startswith("│"):
            row = fit(line, columns - 2)
            result.append(f"{row}{' ' * (columns - 1 - width(row))}{border_color}│{RESET}")
    return result


def natural_box_width(specs):
    return max((width(row) + 2 for row in specs if SGR.sub("", row).startswith("│")),
               default=3)


def choose_logo(state, graphics):
    if state is None:
        try:
            state = (STATE / "fastfetch-logo").read_text().strip()
        except OSError:
            state = "arch"
    if state == "random":
        state = random.choice(SPRITES if graphics else TEXT_LOGOS)
    return state if state in (*TEXT_LOGOS, *SPRITES, "none") else "arch"


def logo_options(logo, columns, rows, screen, graphics):
    if logo == "none":
        return ["--logo-type", "none"], False
    screen_columns, screen_rows, pixels_x, pixels_y = screen
    if logo in SPRITES and graphics:
        image = STATE / "fastfetch" / f"{logo}.gif"
        # Only send the 200px canvas when it fits at the current font size.
        image_cols = (200 * screen_columns + pixels_x - 1) // pixels_x if pixels_x else 20
        image_rows = (200 * screen_rows + pixels_y - 1) // pixels_y if pixels_y else 10
        if image.is_file() and image_cols <= columns and image_rows < rows:
            return ["--kitty-icat", str(image)], True

    path = ART / f"{logo if logo in TEXT_LOGOS else 'arch'}.txt"
    if path.is_file():
        text = re.sub(r"\$[1-9]", "", path.read_text()).splitlines()
        if max(map(width, text), default=0) <= columns:
            return ["--file", str(path)], False
    return (["--logo-type", "small", "--logo", "arch"] if columns >= 13
            else ["--logo-type", "none"]), False


def compose(art, specs, columns, rows):
    art_width = max(map(width, art), default=0)
    box_width = natural_box_width(specs)
    if art and art_width + 3 + box_width <= columns:
        box = render_box(specs, box_width)
        if max(len(art), len(box)) <= rows:
            return [
                f"{logo}{' ' * (art_width + 3 - width(logo))}{box[i]}" if i < len(box) else logo
                for i, logo in enumerate(art + [""] * max(0, len(box) - len(art)))
            ]

    box_width = min(box_width, columns)
    box = render_box(specs, box_width)
    if len(box) + (len(art) + 1 if art else 0) <= rows:
        return [*art, "", *box] if art else box

    # Keep the full art if removing the dividers lets it fit above the box.
    compact = render_box([line for line in specs if not SGR.sub("", line).startswith("├")],
                         box_width)
    if art and len(art) + len(compact) + 1 <= rows:
        return [*art, "", *compact]
    if len(box) + 4 > rows:
        box = compact
    if art and columns >= 7 and len(box) + 4 <= rows:
        logo_color = "".join(SGR.findall(art[0])[:-1])
        small_logo = ["   /\\", "  /  \\", " /_/\\_\\"]
        return [*(f"{logo_color}{line}{RESET}" for line in small_logo), "", *box]
    if len(box) > rows:
        return [*box[:rows - 1], box[-1]] if rows >= 3 else []
    return box


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--columns", type=int)
    parser.add_argument("--lines", type=int)
    parser.add_argument("--logo")
    parser.add_argument("--prompt", action="store_true")
    args = parser.parse_args()
    screen = terminal_size()
    # Leave one cell unused so a line at the right edge cannot trigger autowrap.
    columns = max(1, (args.columns or screen[0]) - 1)
    rows = args.lines or screen[1]
    graphics = bool(os.environ.get("KITTY_WINDOW_ID") and shutil.which("kitten"))
    logo = choose_logo(args.logo, graphics)
    logo_args, image = logo_options(logo, columns, rows, screen, graphics and not args.prompt)

    config = STATE / "fastfetch.jsonc"
    command = ["fastfetch", "--pipe", "false"]
    if config.is_file():
        command += ["--config", str(config), *logo_args, "--logo-position", "top",
                    "--logo-padding-top", "0", "--logo-padding-left", "0",
                    "--logo-padding-right", "0", "--logo-padding-bottom", "0"]
    else:
        command += ["--logo-type", "none"]
    # Fastfetch can skip this renderer when detecting the actual shell.
    result = subprocess.run(command, capture_output=True,
                            env={**os.environ, "FFTS_IGNORE_PARENT": "1"})
    if result.returncode:
        parser.exit(result.returncode, result.stderr.decode(errors="replace"))
    output = result.stdout.decode(errors="replace")
    first_rule = TOP_RULE.search(output)
    if not first_rule or columns < 4:
        print("\n".join(fit(line, columns) for line in output.splitlines()))
        return
    logo_output = output[:first_rule.start()]
    specs = output[first_rule.start():].splitlines()
    if image:
        # icat leaves the cursor at the image's lower-right corner.
        print(f"{logo_output}\r")
        print("\n".join(render_box(specs, min(columns, natural_box_width(specs)))))
    else:
        art = [line for line in logo_output.splitlines() if width(line) > 0]
        print("\n".join(compose(art, specs, columns, max(0, rows - 4))))


if __name__ == "__main__":
    main()
