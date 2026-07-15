import GLib from "gi://GLib"
import { subprocess } from "ags/process"
import { createState } from "ags"

const CONFIG = `${GLib.get_home_dir()}/.config/ags/cava/config`

// Reactive 0..1 bar heights, length = configured `bars` (24). Empty until
// the first cava frame arrives.
export const [bars, setBars] = createState<number[]>([])

// cava raw output: one line per frame, `;`-delimited ascii values 0..100
// (bar_delimiter = 59, the ';' codepoint). Normalize to 0..1 and ignore
// blank/partial lines rather than clobbering the last good frame.
subprocess(["cava", "-p", CONFIG], (line) => {
  const vals = line
    .split(";")
    .filter((s) => s.length)
    .map((s) => Number(s) / 100)
  if (vals.length) setBars(vals)
})
