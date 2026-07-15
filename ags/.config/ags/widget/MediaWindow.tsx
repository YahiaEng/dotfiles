import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import Graphene from "gi://Graphene"
import { With, For } from "ags"
import { media, players, cmd, seek, setVolume, selectPlayer } from "../lib/media"

const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

// Nerd Font / Unicode transport + volume glyphs — MUST be written by
// codepoint, never pasted (recurring project gotcha: PUA glyphs typed
// through the edit tool silently store as empty strings).
const GLYPH_PREV = String.fromCodePoint(0x23ee) // ⏮
const GLYPH_NEXT = String.fromCodePoint(0x23ed) // ⏭
const GLYPH_PLAY = String.fromCodePoint(0x25b6) // ▶
const GLYPH_PAUSE = String.fromCodePoint(0x23f8) // ⏸
const GLYPH_VOLUME = String.fromCodePoint(0x1f50a) // 🔊

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
        spacing={12}
      >
        {/* Metadata row: art + title/artist */}
        <box class="media-meta" spacing={12} orientation={Gtk.Orientation.HORIZONTAL}>
          <image
            class="media-art"
            file={media.as((m) => (m.art ? m.art : ""))}
            pixelSize={64}
          />
          <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
            <label
              class="media-title"
              halign={Gtk.Align.START}
              label={media.as((m) => (m.title ? m.title : "Nothing playing"))}
            />
            <label
              class="media-artist"
              halign={Gtk.Align.START}
              label={media.as((m) => m.artist)}
            />
          </box>
        </box>

        {/* Transport row */}
        <box class="media-transport" spacing={8} halign={Gtk.Align.CENTER}>
          <button class="transport-btn" onClicked={() => cmd("previous")}>
            <label label={GLYPH_PREV} />
          </button>
          <button class="transport-btn" onClicked={() => cmd("play-pause")}>
            <label label={media.as((m) => (m.status === "Playing" ? GLYPH_PAUSE : GLYPH_PLAY))} />
          </button>
          <button class="transport-btn" onClicked={() => cmd("next")}>
            <label label={GLYPH_NEXT} />
          </button>
        </box>

        {/* Seek row — gated on length > 0 (can_seek heuristic).
            `change-value` fires only for user-driven drag/click/scroll (never
            for our programmatic `value` accessor updates), so binding both
            `onChangeValue={seek}` and a live `value` accessor here does NOT
            create a seek-on-every-tick feedback loop. */}
        <With value={media.as((m) => m.length > 0)}>
          {(seekable) =>
            seekable ? (
              <slider
                class="media-seek"
                orientation={Gtk.Orientation.HORIZONTAL}
                drawValue={false}
                widthRequest={260}
                min={0}
                max={media.as((m) => (m.length > 0 ? m.length : 1))}
                value={media.as((m) => m.position)}
                step={1}
                page={10}
                onChangeValue={(_self, _scroll, value) => {
                  seek(value)
                  return false
                }}
              />
            ) : (
              <label class="media-seek-disabled" label="Not seekable" />
            )
          }
        </With>

        {/* Volume row — same change-value-only pattern as the seek slider. */}
        <box class="media-volume-row" spacing={8} halign={Gtk.Align.CENTER}>
          <label label={GLYPH_VOLUME} />
          <slider
            class="media-volume"
            orientation={Gtk.Orientation.HORIZONTAL}
            drawValue={false}
            widthRequest={160}
            min={0}
            max={1}
            value={media.as((m) => (m.volume >= 0 ? m.volume : 0))}
            step={0.05}
            page={0.1}
            onChangeValue={(_self, _scroll, value) => {
              setVolume(value)
              return false
            }}
          />
        </box>

        {/* Player switcher */}
        <box class="media-switcher" spacing={6} halign={Gtk.Align.CENTER}>
          <For each={players}>
            {(p: any) => (
              <button
                class={p.active ? "switcher-btn switcher-btn-active" : "switcher-btn"}
                onClicked={() => selectPlayer(p.id)}
              >
                <label label={p.label} />
              </button>
            )}
          </For>
        </box>
      </box>
    </window>
  )
}
