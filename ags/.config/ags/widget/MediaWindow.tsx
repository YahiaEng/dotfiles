import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import Pango from "gi://Pango"
import { With, For } from "ags"
import { media, players, seekable, seekLength, cmd, seek, setVolume, selectPlayer } from "../lib/media"
import Cava from "./Cava"

// Nerd Font / Unicode transport + volume glyphs — MUST be written by
// codepoint, never pasted (recurring project gotcha: PUA glyphs typed
// through the edit tool silently store as empty strings).
const GLYPH_PREV = String.fromCodePoint(0x23ee) // ⏮
const GLYPH_NEXT = String.fromCodePoint(0x23ed) // ⏭
const GLYPH_PLAY = String.fromCodePoint(0x25b6) // ▶
const GLYPH_PAUSE = String.fromCodePoint(0x23f8) // ⏸
// U+F028 nf-fa-volume_up — a Nerd Font speaker glyph verified present in
// the installed FiraCodeNerdFont (waybar's pulseaudio module renders the
// F026/F027/F028 ramp). Replaces U+1F50A 🔊, a color-emoji codepoint that
// rendered oversized/misaligned and mismatched the monochrome UI.
const GLYPH_VOLUME = String.fromCodePoint(0xf028) //

export default function MediaWindow() {
  let win: Astal.Window

  // Derived art-path accessor, reused by both the background layer and the
  // thumbnail. GTK's fallback "broken image" icon for an empty/invalid file
  // path does not respect pixelSize/widthRequest and can overflow its own
  // allocation (verified live); gate rendering on a real path instead of
  // ever handing Gtk.Image an empty string, and fall back to a plain
  // rgba-tinted placeholder box.
  const artPath = media.as((m) => m.art)

  return (
    <window
      $={(self) => {
        win = self
        // CLICK-AWAY via focus loss. The window is now a small card-sized
        // top-center popup, so the old full-screen GestureClick approach
        // (which relied on the window covering the whole screen to catch
        // outside clicks) no longer works. Instead: keymode ON_DEMAND lets
        // this layer surface hold keyboard focus while the user drags its
        // OWN sliders / clicks its OWN buttons (focus stays inside this
        // toplevel, so is-active stays true — no spurious close). Clicking
        // any OTHER surface deactivates this toplevel, firing
        // notify::is-active -> hide. Esc and the waybar toggle also close.
        self.connect("notify::is-active", () => {
          if (!self.is_active && self.visible) self.hide()
        })
      }}
      name="media"
      namespace="ags-media"
      visible={false}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={Astal.WindowAnchor.TOP}
      marginTop={54}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.TOP}
      application={app}
    >
      <Gtk.EventControllerKey
        onKeyPressed={(_c, keyval) => { if (keyval === Gdk.KEY_Escape) win.hide() }}
      />

      {/* Garuda/HyprPanel underlay: a Gtk.Overlay stack —
          [0] blurred-art background (main child, sizes the card)
          [1] translucent scrim (overlay) — gives the Hyprland `ags-media`
              blur layerrule something to frost through
          [2] cava bars (overlay) — bleed around/behind the thumbnail
          [3] centered album-art thumbnail (overlay)
          [4] meta/transport/sliders/switcher panel (overlay, top) */}
      <overlay
        class="media-card"
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.START}
        overflow={Gtk.Overflow.HIDDEN}
      >
        <With value={artPath}>
          {(path) =>
            path ? (
              <image
                class="media-bg-art"
                file={path}
                pixelSize={420}
                hexpand
                vexpand
                halign={Gtk.Align.FILL}
                valign={Gtk.Align.FILL}
              />
            ) : (
              <box class="media-bg-art media-art-placeholder" hexpand vexpand />
            )
          }
        </With>

        <box $type="overlay" class="media-scrim" hexpand vexpand />

        {/* Art+cava cluster confined to the card's UPPER zone (fixed
            height) so it never overlaps the controls panel anchored at
            the bottom — bars grow from the bottom of THIS zone, with the
            thumbnail centered over them. */}
        <box
          $type="overlay"
          class="cava-layer"
          hexpand
          heightRequest={130}
          halign={Gtk.Align.FILL}
          valign={Gtk.Align.START}
        >
          <Cava />
        </box>

        {/* Smaller centered thumbnail, confined to a fixed clipped box so
            it can never grow past its intended footprint; gated on a real
            art path (see `artPath` above) so GTK's oversized fallback
            "broken image" icon never gets a chance to render at all. */}
        <box
          $type="overlay"
          class="media-thumb"
          widthRequest={76}
          heightRequest={76}
          overflow={Gtk.Overflow.HIDDEN}
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.START}
          marginTop={22}
        >
          <With value={artPath}>
            {(path) =>
              path ? (
                <image
                  file={path}
                  pixelSize={76}
                  hexpand
                  vexpand
                  halign={Gtk.Align.FILL}
                  valign={Gtk.Align.FILL}
                />
              ) : (
                <box class="media-art-placeholder" hexpand vexpand />
              )
            }
          </With>
        </box>

        {/* Fixed-width, card-centered control column. widthRequest pins it
            to the card's inner width and halign=CENTER anchors it dead-
            center in the overlay, so every child row (each halign=CENTER)
            has EQUAL left/right gaps to the card edge. CRITICAL: the title
            MUST be ellipsized (below) — an un-ellipsized Gtk.Label has a
            minimum width equal to its full text, which would force this
            box wider than the card and break the centering of every row. */}
        <box
          $type="overlay"
          class="media-controls"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={8}
          hexpand
          halign={Gtk.Align.FILL}
          valign={Gtk.Align.END}
        >
          {/* Metadata row: title/artist (art now lives in the underlay) */}
          <box class="media-meta" spacing={2} orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER}>
            <label
              class="media-title"
              halign={Gtk.Align.CENTER}
              justify={Gtk.Justification.CENTER}
              xalign={0.5}
              ellipsize={Pango.EllipsizeMode.END}
              maxWidthChars={32}
              label={media.as((m) => (m.title ? m.title : "Nothing playing"))}
            />
            <label
              class="media-artist"
              halign={Gtk.Align.CENTER}
              xalign={0.5}
              ellipsize={Pango.EllipsizeMode.END}
              maxWidthChars={36}
              label={media.as((m) => m.artist)}
            />
          </box>

          {/* Transport row */}
          <box class="media-transport" spacing={8} halign={Gtk.Align.CENTER}>
            <button class="transport-btn" onClicked={() => cmd("previous")}>
              <label label={GLYPH_PREV} />
            </button>
            <button class="transport-btn transport-btn-main" onClicked={() => cmd("play-pause")}>
              <label label={media.as((m) => (m.status === "Playing" ? GLYPH_PAUSE : GLYPH_PLAY))} />
            </button>
            <button class="transport-btn" onClicked={() => cmd("next")}>
              <label label={GLYPH_NEXT} />
            </button>
          </box>

          {/* Seek row — gated on the PER-TRACK LATCHED `seekable` accessor,
              not the live `media.length > 0`. Firefox/YouTube drops
              `mpris:length` transiently (notably right after a seek), so
              gating on the raw length made the slider vanish after one
              seek; the latch in lib/media.ts holds seekability steady per
              track. `change-value` fires only for user-driven
              drag/click/scroll (never for our programmatic `value`
              accessor updates), so binding both `onChangeValue={seek}` and
              a live `value` accessor here does NOT create a
              seek-on-every-tick feedback loop. */}
          <With value={seekable}>
            {(isSeekable) =>
              isSeekable ? (
                <slider
                  class="media-seek"
                  orientation={Gtk.Orientation.HORIZONTAL}
                  drawValue={false}
                  widthRequest={320}
                  halign={Gtk.Align.CENTER}
                  min={0}
                  max={seekLength.as((l) => (l > 0 ? l : 1))}
                  value={media.as((m) => m.position)}
                  step={1}
                  page={10}
                  onChangeValue={(_self, _scroll, value) => {
                    seek(value)
                    return false
                  }}
                />
              ) : (
                <label class="media-seek-disabled" halign={Gtk.Align.CENTER} label="Not seekable" />
              )
            }
          </With>

          {/* Volume row — same change-value-only pattern as the seek slider. */}
          <box class="media-volume-row" spacing={8} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
            <label class="volume-glyph" valign={Gtk.Align.CENTER} label={GLYPH_VOLUME} />
            <slider
              class="media-volume"
              orientation={Gtk.Orientation.HORIZONTAL}
              drawValue={false}
              valign={Gtk.Align.CENTER}
              widthRequest={190}
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
      </overlay>
    </window>
  )
}
