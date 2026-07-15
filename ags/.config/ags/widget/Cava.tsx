import { Gtk } from "ags/gtk4"
import { bars } from "../lib/cava"

// Fixed to match cava/config's `bars = 24` — static box count, each with a
// reactively bound heightRequest, avoids recreating 24 widgets every frame
// (which a <For> over the raw array would do at ~60fps).
const BAR_COUNT = 24
const MAX_BAR_HEIGHT = 140
const MIN_BAR_HEIGHT = 3
const BAR_INDICES = Array.from({ length: BAR_COUNT }, (_, i) => i)

// Self-contained: takes no props, reads the reactive `bars` accessor
// directly and renders it as a row of height-scaled bars.
export default function Cava() {
  return (
    <box
      class="cava-underlay"
      orientation={Gtk.Orientation.HORIZONTAL}
      valign={Gtk.Align.END}
      halign={Gtk.Align.FILL}
      spacing={2}
      hexpand
      vexpand
    >
      {BAR_INDICES.map((i) => (
        <box
          class="cava-bar"
          valign={Gtk.Align.END}
          hexpand
          heightRequest={bars.as((vs) =>
            Math.max(MIN_BAR_HEIGHT, Math.round((vs[i] ?? 0) * MAX_BAR_HEIGHT)),
          )}
        />
      ))}
    </box>
  )
}
