import GLib from "gi://GLib"
import { subprocess, exec } from "ags/process"
import { createState } from "ags"

const HOME = GLib.get_home_dir()
const PLAYERS_SH = `${HOME}/.config/hypr/scripts/media-players.sh`
const STATUS_SH = `${HOME}/.config/hypr/scripts/media-status.sh`

const EMPTY = {
  player: "", label: "", status: "", title: "", artist: "",
  album: "", art: "", position: 0, length: 0, volume: -1, can_seek: false,
}

export const [media, setMedia] = createState(EMPTY)
export const [players, setPlayers] = createState<any[]>([])

// Long-lived watcher: one JSON object per line from media-status.sh watch.
subprocess(["bash", STATUS_SH, "watch"], (line) => {
  try { setMedia({ ...EMPTY, ...JSON.parse(line) }) } catch (_e) { /* ignore partial line */ }
})

function refreshPlayers() {
  try { setPlayers(JSON.parse(exec(["bash", PLAYERS_SH, "list"]) || "[]")) } catch { setPlayers([]) }
}
refreshPlayers()

// player ids come only from media.player / players[].id (already
// _valid_id-validated upstream in media-players.sh) — never from track
// metadata (title/artist/album). All backend calls are argv-form arrays.
export function cmd(action: string) {
  const p = media.get().player
  if (p) exec(["bash", PLAYERS_SH, "cmd", p, action])
}

export function seek(pos: number) {
  const p = media.get().player
  if (p) exec(["bash", PLAYERS_SH, "cmd", p, "seek", String(Math.round(pos))])
}

export function setVolume(v: number) {
  const p = media.get().player
  if (p) exec(["bash", PLAYERS_SH, "cmd", p, "volume", String(v)])
}

export function selectPlayer(id: string) {
  exec(["bash", PLAYERS_SH, "select", id])
  refreshPlayers()
}

export { refreshPlayers }
