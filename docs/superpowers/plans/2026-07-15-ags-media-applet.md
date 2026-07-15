# AGS/astal Media Applet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the confirmed-dead eww media popup with a standalone AGS v3 (GTK4) centered media applet — garuda-style blurred-art card, working transport/seek/volume/switcher, cava underlay — keeping waybar/swaync/matugen intact.

**Architecture:** A single full-screen transparent AGS `Astal.Window` (layer `TOP`, keymode `ON_DEMAND`) holds a centered card; clicks outside the card's computed bounds and `Esc` hide it. A `requestHandler` backs `ags request toggle-media` from the waybar segment. The UI binds to reactive state fed by the existing `media-status.sh watch` JSON subprocess and calls `media-players.sh` for actions; a `cava` raw-stdout subprocess drives an audio-reactive bar underlay. matugen writes `~/.local/state/theme/ags.scss`, which `monitorFile` hot-reloads via `app.apply_css`.

**Tech Stack:** AGS v3 (`aylurs-gtk-shell` 3.1.2, AUR), GTK4 + `gtk4-layer-shell`, `gjs`, TypeScript/JSX; `cava` 0.10.7 (extra); existing bash MPRIS backend; matugen; GNU stow.

## Global Constraints

- Toolkit: AGS v3 GTK4 — imports from `ags/gtk4` (`app`, `Astal`, `Gtk`, `Gdk`), `ags` (reactive/JSX), `ags/file` (`monitorFile`), `ags/process` (`subprocess`/`exec`). Pin exact primitive names against the installed 3.1.2 in Task 2; do not assume older astal (`Variable` from `resource:///...`) APIs.
- Reuse MPRIS backend scripts **unchanged**: `~/.config/hypr/scripts/media-status.sh` (`watch` → one JSON object per line), `media-players.sh` (`list` | `select <id>` | `cmd <player> <action>`), `media-art-resolve.sh`. No metadata string ever reaches a command argument (08-07 threat model) — only `_valid_id`-validated player ids and numeric slider values.
- Reproducible: every new file lives in a stow package; deps added to `install.sh`; zero host-only manual state.
- Theming: `style.scss` contains **zero hex literals**; every color is a var `@import`ed from `~/.local/state/theme/ags.scss`.
- No agent-side pointer injection exists — every interaction gate (buttons click, sliders drag) is a **user live-test**; the plan must stop at those gates.
- Window name is `media` (so `ags request toggle-media` and `app.get_window("media")` agree). Namespace for Hyprland rules is `ags-media`.

---

### Task 1: Install dependencies and register them in install.sh

**Files:**
- Modify: `install.sh` (AUR package list + pacman package list — find via grep in Step 1)

- [ ] **Step 1: Locate the package lists**

Run:
```bash
grep -nE 'AUR_PKGS|PACMAN_PKGS|pacman -S|paru -S|packages=\(' install.sh | head
```
Expected: the arrays/commands where official-repo and AUR packages are declared (CLAUDE.md references an `AUR_PKGS` list ~line 150).

- [ ] **Step 2: Add `cava` to the pacman/official list and `aylurs-gtk-shell` to the AUR list**

Edit `install.sh` to add `cava` alongside other `extra`-repo packages and `aylurs-gtk-shell` alongside other AUR packages, matching the existing array/quoting style exactly.

- [ ] **Step 3: Install both on this machine**

Run:
```bash
sudo pacman -S --needed --noconfirm cava
paru -S --needed --noconfirm aylurs-gtk-shell
```
Expected: both install; `gjs` is pulled in as a dependency of `aylurs-gtk-shell`.

- [ ] **Step 4: Verify the toolchain**

Run:
```bash
ags --version && cava -v | head -1 && gjs --version
```
Expected: `ags` prints a 3.x version; `cava` prints 0.10.7; `gjs` prints a version.

- [ ] **Step 5: Commit**

```bash
git add install.sh
git commit -m "build(media): add aylurs-gtk-shell + cava deps for AGS media applet"
```

---

### Task 2: Scaffold the AGS project and prove a clickable centered window (CRITICAL input-viability gate)

This is the fail-fast gate: it proves AGS delivers pointer clicks to widgets on this exact Hyprland — the thing eww could not do — **before** any further work.

**Files:**
- Create: `ags/.config/ags/app.tsx`
- Create: `ags/.config/ags/tsconfig.json` (from `ags init` output)
- Create: `ags/.config/ags/env.d.ts` (from `ags init` output)
- Create: `ags/.config/ags/style.scss`
- Create: `ags/.config/ags/widget/MediaWindow.tsx`

**Interfaces:**
- Produces: `MediaWindow()` — a component that returns the full-screen `Astal.Window` named `media`, keymode `ON_DEMAND`, layer `TOP`, containing a centered card box; hides on `Esc` and on click outside the card's bounds. Consumed by `app.tsx`.
- Produces: `ags request toggle-media` — toggles the `media` window's visibility. Consumed by waybar (Task 6).

- [ ] **Step 1: Scaffold into a temp dir, then move the generated support files in**

Run:
```bash
cd /tmp && rm -rf ags-scaffold && ags init --gtk 4 --directory /tmp/ags-scaffold
ls /tmp/ags-scaffold
```
Expected: generates `app.tsx` (or `app.ts`), `tsconfig.json`, `env.d.ts`, `style.scss`, `.gitignore`. Note the exact reactive/JSX import names it uses (e.g. `createState`, `createBinding`, `With`, `For`) — these pin the Global-Constraints primitives.

- [ ] **Step 2: Copy the generated support files into the stow package**

```bash
mkdir -p /home/aorus/dotfiles/ags/.config/ags/widget
cp /tmp/ags-scaffold/tsconfig.json /tmp/ags-scaffold/env.d.ts /home/aorus/dotfiles/ags/.config/ags/
```
(Do not copy the scaffold's demo `app.tsx`/`style.scss` — we author those next.)

- [ ] **Step 3: Write `widget/MediaWindow.tsx` — the window with a single test button**

`ags/.config/ags/widget/MediaWindow.tsx`:
```tsx
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
```

- [ ] **Step 4: Write `app.tsx` — start the app, mount the window, wire the toggle request**

`ags/.config/ags/app.tsx`:
```tsx
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
```

- [ ] **Step 5: Write a minimal `style.scss` so the card is visible**

`ags/.config/ags/style.scss`:
```scss
.media-card {
  min-width: 360px;
  min-height: 200px;
  padding: 24px;
  background-color: rgba(20, 20, 30, 0.92);
  border-radius: 20px;
}
.test-btn { padding: 12px 20px; border-radius: 12px; }
```

- [ ] **Step 6: Run AGS and open the window**

Run:
```bash
cd /home/aorus/dotfiles/ags/.config/ags
# stow not required for local run — run in place:
ags run --directory /home/aorus/dotfiles/ags/.config/ags &
sleep 2
ags request toggle-media
```
Expected: a centered dark card appears with the test button. (If `ags run` errors on TS, fix the import names to match what Step 1's scaffold generated, then re-run.)

- [ ] **Step 7: USER GATE — click test**

Ask the user to: (a) click the test button and confirm the terminal prints `AGS TEST BUTTON CLICKED`; (b) click outside the card and confirm it closes; (c) reopen with `ags request toggle-media` and press `Esc` to confirm it closes.
**If the button does NOT respond, STOP** — AGS also can't deliver clicks and the whole approach is void; report and reassess. **Do not proceed past this gate without a confirmed click.**

- [ ] **Step 8: Commit**

```bash
git add ags/.config/ags/
git commit -m "feat(media): AGS scaffold + centered click-away window (input gate passed)"
```

---

### Task 3: Bind live player state and wire transport/seek/volume/switcher

**Files:**
- Create: `ags/.config/ags/lib/media.ts`
- Modify: `ags/.config/ags/widget/MediaWindow.tsx` (replace the test button with the real controls)

**Interfaces:**
- Consumes: `media-status.sh watch` (one JSON object per line with keys `player,label,status,title,artist,album,art,position,length,volume,can_seek`); `media-players.sh list|select <id>|cmd <player> <action>`.
- Produces: `media` — a reactive accessor of the parsed status object; `players` — a reactive accessor of the `list` JSON array; `cmd(action)`, `seek(pos)`, `setVolume(v)`, `selectPlayer(id)` action helpers. Consumed by `MediaWindow.tsx` and later the card widget.

- [ ] **Step 1: Write `lib/media.ts` — subprocess-fed reactive state + actions**

`ags/.config/ags/lib/media.ts` (adjust `createState`/`Variable` to Task-2 pinned primitive):
```ts
import { subprocess, exec } from "ags/process"
import { createState } from "ags"

const HOME = GLib.get_home_dir()
const PLAYERS_SH = `${HOME}/.config/hypr/scripts/media-players.sh`
const STATUS_SH = `${HOME}/.config/hypr/scripts/media-status.sh`

const EMPTY = { player: "", label: "", status: "", title: "", artist: "",
  album: "", art: "", position: 0, length: 0, volume: -1, can_seek: false }

export const [media, setMedia] = createState(EMPTY)
export const [players, setPlayers] = createState<any[]>([])

// Long-lived watcher: one JSON object per line.
subprocess(["bash", STATUS_SH, "watch"], (line) => {
  try { setMedia({ ...EMPTY, ...JSON.parse(line) }) } catch (_e) { /* ignore partial */ }
})

function refreshPlayers() {
  try { setPlayers(JSON.parse(exec(["bash", PLAYERS_SH, "list"]) || "[]")) } catch { setPlayers([]) }
}
refreshPlayers()

// player ids come only from media.player / players[].id (already _valid_id-checked upstream)
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
export function selectPlayer(id: string) { exec(["bash", PLAYERS_SH, "select", id]); refreshPlayers() }
export { refreshPlayers }
```
Add `import GLib from "gi://GLib"` at the top.

- [ ] **Step 2: Replace the test card with real controls in `MediaWindow.tsx`**

Swap the `<button class="test-btn">` block for the control tree, binding to `media` (use the pinned reactive-bind syntax — `media.as(...)` / `<With>` / `bind`). Transport buttons call `cmd("previous"|"play-pause"|"next")`; seek `Gtk.Scale` `onValueChanged` → `seek(value)` gated on `media.as(m => m.length > 0)`; volume `Gtk.Scale` 0–1 → `setVolume`; switcher lists `players` with `onClicked` → `selectPlayer(id)`. Glyphs written by codepoint (see Task-4 note). Keep the outer window/click-away/Esc from Task 2 intact.

- [ ] **Step 3: Reload and screenshot**

Run:
```bash
ags quit -i media 2>/dev/null; ags run --directory /home/aorus/dotfiles/ags/.config/ags & sleep 2
ags request toggle-media; sleep 1
grim -g "$(hyprctl clients -j | jq -r '.[]|select(.class|test("ags";"i"))|"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | head -1)" /tmp/ags-media.png 2>/dev/null || grim /tmp/ags-media.png
```
Expected: card shows art/title/artist, transport row, seek + volume, switcher. Read `/tmp/ags-media.png` to confirm layout.

- [ ] **Step 4: USER GATE — interaction test**

Ask the user to test: prev/play-pause/next change playback; seek drags and scrubs; volume drags and changes volume; switcher switches active player. Fix any that fail before proceeding.

- [ ] **Step 5: Commit**

```bash
git add ags/.config/ags/lib/media.ts ags/.config/ags/widget/MediaWindow.tsx
git commit -m "feat(media): bind live MPRIS state + working transport/seek/volume/switcher"
```

---

### Task 4: Garuda visual restyle + cava underlay

**Files:**
- Create: `ags/.config/ags/lib/cava.ts`
- Create: `ags/.config/ags/cava/config`
- Create: `ags/.config/ags/widget/Cava.tsx`
- Modify: `ags/.config/ags/widget/MediaWindow.tsx` (blurred-art background + cava-around-art layout)
- Modify: `ags/.config/ags/style.scss` (garuda card styling)
- Modify: `hypr/.config/hypr/config/windowrules.conf` (blur layerrule for `ags-media`)

**Interfaces:**
- Consumes: `media` accessor (art path) from `lib/media.ts`.
- Produces: `bars` — a reactive accessor of a number[] (0..1 heights, length = BАRS) from `lib/cava.ts`; `Cava()` — a widget drawing those bars. Consumed by `MediaWindow.tsx`.

- [ ] **Step 1: Write `cava/config` — raw normalized stdout**

`ags/.config/ags/cava/config`:
```ini
[general]
bars = 24
framerate = 60
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
```

- [ ] **Step 2: Write `lib/cava.ts` — spawn cava, parse frames**

`ags/.config/ags/lib/cava.ts`:
```ts
import { subprocess } from "ags/process"
import { createState } from "ags"
import GLib from "gi://GLib"

const CONFIG = `${GLib.get_home_dir()}/.config/ags/cava/config`
export const [bars, setBars] = createState<number[]>([])

// Each line: "n;n;n;...;" of 0..100 ascii values.
subprocess(["cava", "-p", CONFIG], (line) => {
  const vals = line.split(";").filter((s) => s.length).map((s) => Number(s) / 100)
  if (vals.length) setBars(vals)
})
```

- [ ] **Step 3: Write `widget/Cava.tsx` — draw bars**

Render `bars` as a horizontal row of rectangles whose height scales with each value (a `Gtk.Box` per bar with a bound `heightRequest`, or a `Gtk.DrawingArea` with `setDrawFunc`). Keep it a self-contained widget accepting no props; it reads `bars` directly.

- [ ] **Step 4: Restyle `MediaWindow.tsx` to the garuda underlay**

Layout: card is an `overlay` — background layer = album art (`Gtk.Picture` from `media.as(m => m.art)`) scaled to cover + a scrim box; the `Cava()` widget sits above the background and *behind* a smaller centered album-art thumbnail (bars bleed past its edges); the meta + transport + sliders + switcher overlay on top. Use `Gtk.Overlay` for the stacking.

- [ ] **Step 5: Garuda styling in `style.scss`**

Rounded-pill controls, translucent scrim, accent-colored bars, thumbnail radius. Still using literal colors here is FORBIDDEN past Task 5 — for this task use temporary neutral rgba values; Task 5 swaps them for palette vars. Circular transport buttons, ~360px card.

- [ ] **Step 6: Add the Hyprland blur layerrule**

Append to `hypr/.config/hypr/config/windowrules.conf`:
```
layerrule = blur, ags-media
layerrule = ignorealpha 0.5, ags-media
```

- [ ] **Step 7: Glyphs by codepoint (recurring gotcha)**

Any Nerd Font glyphs (transport icons, volume, chevron) MUST be written by codepoint, not pasted — PUA glyphs typed through the edit tool store as empty strings. Set them in TS via `String.fromCharCode(0x...)` or verified escapes, and confirm with a parse check before the screenshot.

- [ ] **Step 8: Reload, screenshot, USER GATE**

Run the reload+grim from Task 3 Step 3. Read the PNG: confirm blurred-art card with bars bleeding around the thumbnail and overlaid controls. Then ask the user to confirm cava bars animate to audio and the look matches the garuda intent.

- [ ] **Step 9: Commit**

```bash
git add ags/.config/ags/ hypr/.config/hypr/config/windowrules.conf
git commit -m "feat(media): garuda card visual + cava audio-reactive underlay"
```

---

### Task 5: matugen theming — template, config entry, hot reload

**Files:**
- Create: `matugen/.config/matugen/templates/ags-colors.scss`
- Modify: `matugen/.config/matugen/config.toml` (add `[templates.ags]` + post_hook)
- Modify: `ags/.config/ags/style.scss` (replace literal colors with `@import`ed vars)
- Modify: `ags/.config/ags/app.tsx` (monitorFile → apply_css hot reload)

**Interfaces:**
- Consumes: matugen palette engine.
- Produces: `~/.local/state/theme/ags.scss` (named color SCSS vars); a running-AGS CSS reload on theme switch.

- [ ] **Step 1: Create the template mirroring the eww one**

Read `matugen/.config/matugen/templates/eww-colors.scss` for the exact matugen var syntax, then create `ags-colors.scss` emitting the same palette as SCSS `$name: #hex;` lines (background, surface, surface_variant, on_surface, on_surface_variant, primary, on_primary, tertiary, outline — matching what `style.scss` needs).

- [ ] **Step 2: Register the template in `config.toml`**

Append after the `[templates.eww]` block:
```toml
[templates.ags]
input_path = "~/.config/matugen/templates/ags-colors.scss"
output_path = "~/.local/state/theme/ags.scss"
post_hook = "ags request reload-css 2>/dev/null || true"
```

- [ ] **Step 3: Add the `reload-css` request + monitorFile in `app.tsx`**

Extend `requestHandler` with a `reload-css` case that calls `app.apply_css(compiledCss, true)`; and in `main()`, `monitorFile` the state file to auto-apply on change:
```tsx
import { monitorFile } from "ags/file"
// inside main():
monitorFile(`${GLib.get_home_dir()}/.local/state/theme/ags.scss`, () => app.apply_css(style, true))
```
(`style` is the imported compiled scss; `@import` of the state file resolves at compile — if AGS compiles scss at load only, the `reload-css` request should re-read+recompile; pin the exact reapply call against 3.1.2 in this step.)

- [ ] **Step 4: Swap literal colors for palette vars in `style.scss`**

Add `@import "../../.local/state/theme/ags.scss";` at the top (mirroring eww's relative import) and replace every rgba/hex from Task 4 with `$primary`, `$surface`, etc. Verify zero hex literals:
```bash
grep -nE '#[0-9a-fA-F]{3,8}' ags/.config/ags/style.scss
```
Expected: no matches (outside comments).

- [ ] **Step 5: Verify theme switch recolors the applet**

Run a static theme apply and a matugen apply; open the applet after each; confirm colors change with no manual step. (Use the repo's existing theme-apply entrypoint.)

- [ ] **Step 6: Commit**

```bash
git add matugen/.config/matugen/ ags/.config/ags/style.scss ags/.config/ags/app.tsx
git commit -m "feat(media): matugen theming + CSS hot-reload for AGS applet"
```

---

### Task 6: Integration, retirement of eww popup, autostart, final reproducibility

**Files:**
- Modify: `waybar/.config/waybar/modules.jsonc:278` and `waybar/.config/waybar/config-vertical.jsonc:91` (`custom/media` on-click)
- Modify: `hypr/.config/hypr/config/autostart.conf` (start AGS; maybe remove eww)
- Modify: `eww/.config/eww/eww.yuck` (remove `media-popup` + `media-backdrop`)
- Delete: `hypr/.config/hypr/scripts/media-popup-open.sh`, `hypr/.config/hypr/scripts/media-popup-close.sh`
- Modify: `matugen/.config/matugen/config.toml` (remove `[templates.eww]` only if eww fully retired)

**Interfaces:**
- Consumes: `ags request toggle-media` (Task 2), the AGS daemon.

- [ ] **Step 1: Repoint the waybar segment**

In both `modules.jsonc` and `config-vertical.jsonc`, change the `custom/media` `"on-click"` from `~/.config/hypr/scripts/media-popup-open.sh` to `ags request toggle-media`.

- [ ] **Step 2: Autostart the AGS daemon**

Read `hypr/.config/hypr/config/autostart.conf`; add an `exec-once` for AGS following the file's existing `uwsm app --`/exec convention, e.g.:
```
exec-once = uwsm app -- ags run --directory ~/.config/ags
```

- [ ] **Step 3: Check whether eww has any other consumer**

Run:
```bash
grep -rn 'eww ' hypr/ waybar/ --include=*.sh --include=*.jsonc --include=*.conf | grep -v media-popup
grep -c 'defwindow' eww/.config/eww/eww.yuck
```
Decide: if `media-popup`/`media-backdrop` are eww's only windows and nothing else calls `eww`, remove eww from `autostart.conf`, drop `[templates.eww]` from `config.toml`, and note eww can be dropped from `install.sh` (leave the package — harmless — but stop autostarting). If eww has other uses, keep eww running and only remove the two media windows.

- [ ] **Step 4: Remove the eww media windows + retired scripts**

Delete the `defwindow media-popup` and `defwindow media-backdrop` blocks (and now-unused `media-center`/backdrop widgets/deflisten if nothing else references them) from `eww.yuck`. `git rm` the two `media-popup-*.sh` scripts.

- [ ] **Step 5: Full end-to-end via stow**

Run:
```bash
cd /home/aorus/dotfiles && stow ags
ags quit -i media 2>/dev/null; uwsm app -- ags run --directory ~/.config/ags & sleep 2
# reload waybar so the new on-click is live
pkill -SIGUSR2 waybar
```
Then USER GATE: click the waybar media segment → applet opens centered; controls work; cava animates; click-away/Esc close; theme switch recolors. Confirm the old eww popup no longer appears.

- [ ] **Step 6: Commit**

```bash
git add -A ags waybar hypr eww matugen install.sh
git commit -m "feat(media): retire eww popup, wire waybar+autostart to AGS applet"
```

---

## Self-Review

- **Spec coverage:** deps+install.sh (T1), toolkit/window/click-away (T2), backend reuse + transport/seek/volume/switcher (T3), garuda visual + cava underlay + blur layerrule (T4), matugen template + hot reload (T5), waybar/autostart integration + eww retirement + reproducibility (T6). Success criteria 1–6 all map to a task's USER GATE or verification step. ✔
- **Placeholder scan:** concrete code for window/click-away/CSS-reload/cava/media bridge; the two acknowledged API-pinning points (reactive primitive name; exact apply_css reapply call) are explicit "pin against 3.1.2" instructions tied to the scaffold output, not vague TODOs — unavoidable given AGS v3's version-sensitive API and no local test harness. ✔
- **Type consistency:** `media`/`players` accessors, `cmd/seek/setVolume/selectPlayer`, `bars`, window name `media`, namespace `ags-media`, request verbs `toggle-media`/`reload-css` used consistently across tasks. ✔
- **Input-viability front-loaded:** Task 2 Step 7 is a hard STOP gate proving AGS clicks work before any further investment — directly de-risks the eww failure mode. ✔
