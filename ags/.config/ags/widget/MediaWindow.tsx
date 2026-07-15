import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import Graphene from "gi://Graphene"

const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

// Hide the window when the click lands outside the card's bounds.
function onClickOutside(x: number, y: number, win: Astal.Window, card: Gtk.Widget) {
  const [ok, rect] = card.compute_bounds(win)
  if (!ok) return
  if (!rect.contains_point(new Graphene.Point({ x, y }))) win.hide()
}

export default function MediaWindow() {
  let win: Astal.Window
  let card: Gtk.Box
  return (
    <window
      $={(self) => (win = self)}
      name="media"
      namespace="ags-media"
      visible={false}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.TOP}
      application={app}
    >
      <Gtk.EventControllerKey
        onKeyPressed={(_c, keyval) => { if (keyval === Gdk.KEY_Escape) win.hide() }}
      />
      <Gtk.GestureClick onPressed={(_c, _n, x, y) => onClickOutside(x, y, win, card)} />
      <box
        $={(self) => (card = self)}
        class="media-card"
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
        orientation={Gtk.Orientation.VERTICAL}
      >
        <button
          class="test-btn"
          onClicked={() => print("AGS TEST BUTTON CLICKED")}
        >
          <label label="Click me — then check the terminal" />
        </button>
      </box>
    </window>
  )
}
