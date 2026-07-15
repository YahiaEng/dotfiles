import app from "ags/gtk4/app"
import style from "./style.scss"
import MediaWindow from "./widget/MediaWindow"

app.start({
  instanceName: "media",
  css: style,
  main() {
    MediaWindow()
  },
  requestHandler(argv: string[], res: (response: string) => void) {
    const [request] = argv
    if (request === "toggle-media") {
      const win = app.get_window("media")
      if (win) win.visible = !win.visible
      return res("ok")
    }
    res(`unknown request: ${request}`)
  },
})
