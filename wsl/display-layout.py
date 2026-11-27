#!/usr/bin/env python3
"""Translate Windows display rectangles into Hyprland's logical coordinates."""

import argparse
import json
import math
import subprocess
import sys
import time
from dataclasses import dataclass
from itertools import product
from pathlib import Path

SCALE_UNITS = 120  # Wayland fractional-scale protocol
MANUAL_SCALES = (120, 135, 144, 150, 165, 180, 192, 195, 210, 225, 240, 270, 300, 330, 360)


def valid_scales(width, height):
    short, long = sorted((width, height))
    # Leave enough logical space for dialogs in either orientation. Hyprland
    # also requires whole logical pixels at the chosen scale.
    limit = max(SCALE_UNITS, min(3 * SCALE_UNITS, short * SCALE_UNITS // 720,
                                 long * SCALE_UNITS // 1024))
    return [units for units in range(SCALE_UNITS, limit + 1)
            if width * SCALE_UNITS % units == 0 and height * SCALE_UNITS % units == 0]


def automatic_scale(width, height, windows_percent, panel_dpi, valid):
    # Use a comfortable density and a 1080px short edge as a readability floor.
    target = max(1, windows_percent / 100, panel_dpi / 110, min(width, height) / 1080) * SCALE_UNITS
    return min(valid, key=lambda units: (abs(units - target), units))


@dataclass(frozen=True)
class Display:
    x: int
    y: int
    width: int
    height: int
    scale: int

    @property
    def logical_width(self):
        return self.width * SCALE_UNITS // self.scale

    @property
    def logical_height(self):
        return self.height * SCALE_UNITS // self.scale


def proximity(a, b):
    dx = max(0, a.x - b.x - b.width, b.x - a.x - a.width)
    dy = max(0, a.y - b.y - b.height, b.y - a.y - a.height)
    shared_width = min(a.x + a.width, b.x + b.width) - max(a.x, b.x)
    shared_height = min(a.y + a.height, b.y + b.height) - max(a.y, b.y)
    return dx * dx + dy * dy, -max(0, shared_width, shared_height)


def axis_offset(start, size, scale, anchor_start, anchor_size, anchor_scale):
    # Match the midpoint of the shared edge in each screen's units. When
    # the intervals are disjoint, retain the gap in the anchor's units.
    if start + size <= anchor_start:
        return round((start + size - anchor_start) / anchor_scale - size / scale)
    if anchor_start + anchor_size <= start:
        return round((start - anchor_start) / anchor_scale)
    shared_center = (max(start, anchor_start) + min(start + size, anchor_start + anchor_size)) / 2
    return round((shared_center - anchor_start) / anchor_scale - (shared_center - start) / scale)


def place(display, anchor, anchor_position, occupied):
    scale = display.scale / SCALE_UNITS
    anchor_scale = anchor.scale / SCALE_UNITS
    x = anchor_position[0] + axis_offset(display.x, display.width, scale, anchor.x, anchor.width, anchor_scale)
    y = anchor_position[1] + axis_offset(display.y, display.height, scale, anchor.y, anchor.height, anchor_scale)
    width, height = display.logical_width, display.logical_height

    # With three or more independently scaled outputs, an ideal placement
    # can hit a second neighbor. Find the nearest free position at an edge.
    xs, ys = {x}, {y}
    for left, top, right, bottom in occupied:
        xs.update((left - width, right))
        ys.update((top - height, bottom))
    return min(
        ((px, py) for px, py in product(xs, ys)
         if all(px + width <= left or px >= right or py + height <= top or py >= bottom
                for left, top, right, bottom in occupied)),
        key=lambda p: ((p[0] - x) ** 2 + (p[1] - y) ** 2, p),
    )


def logical_layout(displays):
    positions = {0: (0, 0)}
    remaining = set(range(1, len(displays)))
    while remaining:
        index, neighbor = min(
            product(remaining, positions),
            key=lambda pair: (proximity(displays[pair[0]], displays[pair[1]]), pair),
        )
        occupied = [(x, y, x + displays[i].logical_width, y + displays[i].logical_height)
                    for i, (x, y) in positions.items()]
        positions[index] = place(displays[index], displays[neighbor], positions[neighbor], occupied)
        remaining.remove(index)

    left = min(x for x, _ in positions.values())
    top = min(y for _, y in positions.values())
    return [(positions[i][0] - left, positions[i][1] - top) for i in range(len(displays))]


def read_outputs(overrides):
    outputs = []
    for line in sys.stdin:
        name, x, y, width, height, *metadata = line.split()
        x, y, width, height = map(int, (x, y, width, height))
        windows_percent, panel_dpi = map(int, metadata[:2] or (0, 0))
        device = metadata[2] if len(metadata) >= 3 and metadata[2] != "-" else name
        valid = valid_scales(width, height)
        auto = automatic_scale(width, height, windows_percent, panel_dpi, valid)
        saved = overrides.get(device)
        scale = saved if saved in valid else auto
        choices = sorted(set(valid).intersection((*MANUAL_SCALES, auto, saved)))
        outputs.append((Display(x, y, width, height, scale), {
            "name": name, "id": device, "saved": saved, "choices": choices,
        }))
    return outputs


def hyprland_json(command):
    return json.loads(subprocess.check_output(
        ["hyprctl", command, "-j"], timeout=1, stderr=subprocess.DEVNULL,
    ))


def layout_matches(displays, positions, monitors):
    if len(monitors) != len(displays):
        return False
    for i, (display, (x, y)) in enumerate(zip(displays, positions), 1):
        output = monitors.get(f"Virtual-{i}")
        if output is None:
            return False
        if (output["width"], output["height"], output["x"], output["y"]) != (display.width, display.height, x, y):
            return False
        if not math.isclose(output["scale"], display.scale / SCALE_UNITS, abs_tol=0.0001):
            return False
    return True


def wait_for_layout(displays, positions):
    for _ in range(12):
        try:
            monitors = {output["name"]: output for output in hyprland_json("monitors")}
            if layout_matches(displays, positions, monitors):
                return True
        except (ValueError, subprocess.SubprocessError):
            pass
        time.sleep(0.15)
    return False


def bar_spans(displays, positions, layers):
    spans = {}
    for i, (display, (x, y)) in enumerate(zip(displays, positions), 1):
        right, bottom = x + display.logical_width, y + display.logical_height
        name = f"Virtual-{i}"
        for level in layers.get(name, {}).get("levels", {}).values():
            for surface in level:
                namespace = surface["namespace"]
                if namespace != "quickshell-bar" and not namespace.startswith("quickshell-baredge-"):
                    continue
                sx, sy, width, height = (surface[k] for k in ("x", "y", "w", "h"))
                if not (width > 0 and height > 0 and x <= sx <= right - width and y <= sy <= bottom - height):
                    return None
                # The pinned insets on the stretch axis should survive a
                # resize. A stale, narrower bar can still fit inside the output.
                horizontal = namespace.endswith(("-top", "-bottom")) or (
                    namespace == "quickshell-bar" and width >= height
                )
                spans[f"{name}/{namespace}"] = (
                    [sx - x, right - sx - width] if horizontal else [sy - y, bottom - sy - height]
                )
    return spans


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--overrides", type=Path)
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--options", action="store_true")
    action.add_argument("--set", nargs=2, metavar=("DISPLAY_ID", "SCALE"))
    action.add_argument("--wait-live", action="store_true")
    action.add_argument("--check-bars", action="store_true")
    action.add_argument("--snapshot-bars", action="store_true")
    parser.add_argument("--previous-bars", type=json.loads, default={})
    args = parser.parse_args()
    overrides = {}
    if args.overrides is not None:
        try:
            overrides = json.loads(args.overrides.read_text())
        except FileNotFoundError:
            pass

    outputs = read_outputs(overrides)
    if args.options:
        print(json.dumps({f"Virtual-{i}": options for i, (_, options) in enumerate(outputs, 1)}))
        return
    if args.set:
        device, value = args.set
        options = next((options for _, options in outputs if options["id"] == device), None)
        if options is None:
            sys.exit("The display is no longer connected.")
        if value == "auto":
            overrides.pop(device, None)
        elif value.isascii() and value.isdecimal() and int(value) in options["choices"]:
            overrides[device] = int(value)
        else:
            sys.exit("That scale is unavailable at the current resolution.")
        print(json.dumps(overrides, indent=2, sort_keys=True))
        return

    displays = [display for display, _ in outputs]
    positions = logical_layout(displays)
    if args.wait_live:
        sys.exit(0 if wait_for_layout(displays, positions) else 1)
    if args.check_bars or args.snapshot_bars:
        try:
            spans = bar_spans(displays, positions, hyprland_json("layers"))
        except (ValueError, subprocess.SubprocessError):
            spans = None
        if args.snapshot_bars:
            print(json.dumps(spans or {}))
            return
        healthy = spans is not None and all(args.previous_bars.get(name, margins) == margins
                                            for name, margins in spans.items())
        sys.exit(0 if healthy else 1)

    for index, ((x, y), display) in enumerate(zip(positions, displays), 1):
        print(f"Virtual-{index} {x}x{y} {display.scale / SCALE_UNITS:.8f}")


if __name__ == "__main__":
    main()
