import app from "ags/gtk4/app"
import style from "./style.scss"
import MediaWindow from "./widget/MediaWindow"
import { monitorFile } from "ags/file"
import { exec } from "ags/process"
import GLib from "gi://GLib"

// 10-05 CSS hot-reload (MEDIA-03).
//
// AGS's own bundler compiles `./style.scss` to a plain CSS string via the
// `sass` binary ONCE, at process start (`import style from "./style.scss"`)
// — that import is a bundle-time snapshot, not a live binding, so a
// re-import at runtime would still yield the stale string. The installed
// AGS 3.1.2 `App.apply_css(style: string, reset = false)` (ground-truthed
// directly against /usr/share/ags/js/lib/gtk4/app.ts) accepts either a raw
// CSS string OR a path to an existing file (`GLib.file_test(style,
// GLib.FileTest.EXISTS)` gates which); it does NOT compile SCSS itself —
// Gtk.CssProvider only understands plain CSS. So `reload-css` must
// shell out to `sass` again at runtime (same binary AGS's own bundler
// uses, confirmed on-PATH per the 10-02 sass-on-PATH launch requirement),
// recompiling the SAME style.scss entry point (which @imports the
// freshly matugen-rendered ~/.local/state/theme/ags.scss), then apply the
// resulting CSS text with `reset: true` so `app.reset_css()` first removes
// the stale provider before the new one is added (confirmed via
// `App.apply_css` -> `if (reset) this.reset_css()`).
//
// Live-reproduced bug: passing the STOWED symlink path
// (~/.config/ags/style.scss) straight to our own `sass` subprocess makes
// `@import "../../../../.local/state/theme/ags.scss"` fail ("Can't find
// stylesheet to import") — plain `sass` resolves relative imports against
// the path AS GIVEN and does NOT collapse the symlink the way AGS's own
// Go bundler does at bundle time (see style.scss's header comment for the
// full asymmetry). Fix: resolve the symlink to its real on-disk path via
// `realpath` ONCE at module load (the stow target doesn't change during a
// running session) and feed `sass` THAT path, matching AGS's own bundler
// resolution exactly so the same @import line works both times.
const STYLE_LINK = `${GLib.get_home_dir()}/.config/ags/style.scss`
const STYLE_ENTRY = exec(["realpath", STYLE_LINK])
const PALETTE_STATE = `${GLib.get_home_dir()}/.local/state/theme/ags.scss`

function reloadCss() {
  try {
    const css = exec(["sass", "--no-source-map", STYLE_ENTRY])
    app.apply_css(css, true)
  } catch (e) {
    console.error(`reload-css: sass compile of ${STYLE_ENTRY} failed: ${e}`)
  }
}

app.start({
  instanceName: "media",
  css: style,
  main() {
    MediaWindow()
    // Auto-recolor whenever matugen re-renders the palette — no manual
    // restart or reload-css request required for the common case (a
    // theme switch while the applet daemon is already running).
    monitorFile(PALETTE_STATE, () => reloadCss())
  },
  requestHandler(argv: string[], res: (response: string) => void) {
    const [request] = argv
    if (request === "toggle-media") {
      const win = app.get_window("media")
      if (win) win.visible = !win.visible
      return res("ok")
    }
    if (request === "reload-css") {
      reloadCss()
      return res("ok")
    }
    res(`unknown request: ${request}`)
  },
})
