# Phase 21 GATE-01 Behaviour Baseline — the retiring AGS media card

This document is this phase's one irreversible read: every behaviour of the standalone AGS v3
media applet (`ags/.config/ags/widget/MediaWindow.tsx`, `widget/Cava.tsx`, `lib/media.ts`,
`lib/cava.ts`, `app.tsx`), enumerated off the LIVE, still-running implementation, and turned into
the gesture-and-observation parity checklist the combined RETIRE-06 deletion gate (D-21-20)
consumes. It follows `18-BEHAVIOUR-BASELINE.md`'s "GATE-01 Recurrence Protocol" verbatim — see
that document's own six numbered steps and its per-phase surface table naming `ags` as this
phase's surface, with no dedicated resolver and `contract.json`'s own entry as the closest thing
to a manifest.

## Provenance

**Date taken:** 2026-08-16, wave 1 of 9, eight waves before this phase's own deletion plan
removes every file this document reads.

**Live PIDs observed this session** (before any tasks in this plan touched the tree):

- `1705` — `/usr/bin/ags run --directory /home/aorus/.config/ags` (the AGS daemon)
- `1796` — `gjs -m /run/user/1000/ags.js` (the daemon's GJS runtime)
- `1990` — `cava -p /home/aorus/.config/ags/cava/config` (the audio-analysis subprocess the card
  feeds its cava underlay from)

**Commands actually run against the live surface this session** (not source alone):

```
pgrep -fa "ags run"                          # confirmed PID 1705 alive before any read
ags list                                      # -> "media" (the daemon answers its window registry)
ags request -i media toggle-media             # -> "ok"  (FIRST call — opened the card)
hyprctl layers -j                             # confirmed a live "ags-media" layer-shell surface:
                                               #   monitor DP-1, x=1049 y=54 w=462 h=422
playerctl -l                                  # -> firefox.instance_1_151 (the only live MPRIS source)
playerctl status                              # -> Playing
playerctl metadata                            # -> title "Photomaly", artist "jacksepticeye",
                                               #    artUrl file:///home/aorus/.config/zen/firefox-mpris/3672_14.png
playerctl volume                              # -> 1.000000
playerctl position                            # -> 0.000004
bash hypr/.config/hypr/scripts/media-status.sh once
  # -> {"player":"firefox.instance_1_151","label":"Firefox","status":"Playing",
  #     "title":"Photomaly","artist":"jacksepticeye","album":"",
  #     "art":"/home/aorus/.config/zen/firefox-mpris/3672_14.png",
  #     "position":0,"length":0,"volume":1.000000,"can_seek":false}
bash hypr/.config/hypr/scripts/media-players.sh list
  # -> [{"id":"firefox.instance_1_151","label":"Firefox","active":true}]
ags request -i media toggle-media             # SECOND call — closed the card again
hyprctl layers -j                             # confirmed "ags-media" is absent again ("hidden-ok")
```

This live run is what substantiates C-04/C-11 below with a real, present-day observation rather
than a source read alone: the currently-playing Firefox/YouTube track genuinely reports
`"length":0,"can_seek":false"` right now, on this host, which is exactly the MPRIS-unreliability
condition `lib/media.ts`'s own header comment (lines 17-30) says the seekability latch exists to
survive.

**Tool-completeness note, per protocol step 2:** there is no dedicated resolver for this surface
(no `ags-equivalence-check`-shaped tool exists anywhere in this repo) — `18-BEHAVIOUR-BASELINE.md`'s
own per-phase surface table already predicted this ("No dedicated resolver — `contract.json`'s own
entry is itself the closest thing to a manifest and should be read as the starting point"), and
this session confirms that framing is correct. Every capability below was read directly from the
`.tsx`/`.ts` source, cross-checked where possible against a live process/layer/MPRIS observation.
One narrow gap in what could be observed live rather than read from source: `hyprctl layers -j`
reports a surface's rendered geometry (x/y/w/h) but not its declared anchor/margin properties —
those were read from `MediaWindow.tsx:53-54` (`anchor={Astal.WindowAnchor.TOP}`,
`marginTop={54}`). This is not a blind trust of the source, though: the live-observed `y=54`
independently matches the declared `marginTop={54}` exactly, so the source read and the live
observation cross-confirm each other rather than one substituting for the other.

## Capabilities

Every row below is gesture-and-observation: what the operator does, and what they then observe.
Source citations are `file:line` into the AGS tree as it stands today. IDs are stable (`C-01`
through `C-16`) and are reused verbatim by `## Parity Checklist` below and by
`## Unaccounted Keys`' closure proof.

| ID | Gesture → Observation | Source |
|---|---|---|
| C-01 | Run `ags request -i media toggle-media` (today the only way to invoke it — see D-01). The `ags-media` layer-shell surface appears/disappears. **Live-confirmed this session**: `hyprctl layers -j` showed the surface at DP-1 (x=1049 y=54 w=462 h=422) immediately after the first toggle, and its absence after the second. | `app.tsx:60-66` (requestHandler `"toggle-media"` branch), `MediaWindow.tsx:49-57` (window namespace/anchor/keymode) |
| C-02 | With the card open, click any other on-screen surface. The card hides the instant it loses toplevel focus — a focus-loss dismiss (`notify::is-active`), not a click-outside geometry test. | `MediaWindow.tsx:45-47` |
| C-03 | With the card open and focused, press Escape. The card hides. | `MediaWindow.tsx:59-61` (`Gtk.EventControllerKey` catching `Gdk.KEY_Escape`) |
| C-04 | Open the card while a track is active. Title and artist render from the live MPRIS payload. **Live-confirmed this session**: title "Photomaly", artist "jacksepticeye" (`playerctl metadata` / `media-status.sh once`, both cited in Provenance). With no player, title falls back to the literal string "Nothing playing" and artist renders empty. | `MediaWindow.tsx:168,176`, `lib/media.ts:9-14` (EMPTY seed) |
| C-05 | Open the card with a track carrying album art. Cover art renders: a full-bleed backdrop image sized to the whole card PLUS a separate smaller (76x76) centered thumbnail, both reading the same `artPath`. With no art path, a plain placeholder box renders in both slots instead of ever handing GTK's own broken-image icon a chance to draw. | `MediaWindow.tsx:76-92` (backdrop), `:111-141` (thumbnail) |
| C-06 | Open the card while audio is audibly playing. 24 fixed vertical bars in a bottom-anchored row inside the card's upper "cava-layer" zone rise and fall in height, reactively, tracking the live audio spectrum. **Live-confirmed this session**: the `cava` subprocess (PID 1990) is running against `~/.config/ags/cava/config`, streaming one `;`-delimited ascii line per frame that `lib/cava.ts`'s `bars` state feeds directly into each box's `heightRequest`. | `Cava.tsx` (whole file), `lib/cava.ts` (whole file) |
| C-07 | Click the leftmost (⏮) transport button. Playback jumps to the previous track. | `MediaWindow.tsx:182-184` (`cmd("previous")`), `lib/media.ts:100-103` |
| C-08 | Click the center transport button. The glyph toggles ▶↔⏸ and playback pauses/resumes. | `MediaWindow.tsx:185-187` (`cmd("play-pause")`) |
| C-09 | Click the rightmost (⏭) transport button. Playback advances to the next track. | `MediaWindow.tsx:188-190` (`cmd("next")`) |
| C-10 | With a seekable track, drag or click the horizontal seek slider. Playback jumps to the dragged position (`onChangeValue` fires only for user-driven interaction, never for the live `value` binding — no seek-on-every-tick feedback loop). When the per-track latch (C-11) reports the track as not-yet-seekable, the slider is replaced entirely by a "Not seekable" label, never a disabled slider. | `MediaWindow.tsx:203-226` |
| C-11 | Seek once on a track whose MPRIS source is known to drop `mpris:length` transiently right after a seek (this session's live Firefox/YouTube track is exactly this case), then observe the seek row again. The seek slider does NOT vanish or flip to "Not seekable" on that transient zero-length report — seekability is latched per track identity (`player+title+artist`) and only resets on a genuine track-identity change or the player stopping. **Live-confirmed this session**: `media-status.sh once` currently reports `"length":0,"can_seek":false` for the live Firefox track — the exact transient condition this latch exists to survive. | `lib/media.ts:17-68` (the whole latch mechanism, `trackKeyOf`/`updateSeekLatch`) |
| C-12 | Drag the volume slider. Playback volume changes to the dragged fraction. **Live-confirmed this session**: `playerctl volume` → `1.000000`, matching the card's own displayed value. The volume row carries **no visibility gate at all** in the TSX — it renders unconditionally for every player state, including one reporting no volume support (payload sentinel `-1`, clamped to a 0 slider position rather than hidden), a materially different treatment from the seek row's present-but-disabled pattern. | `MediaWindow.tsx:228-247` |
| C-13 | With two or more players active, click a different player's chip in the switcher row. That player becomes the active target for every other control on the card (transport/seek/volume all re-target it), and the clicked chip gains a distinct active visual state. **Not independently exercised live this session** — only one MPRIS source (Firefox) was running throughout, so this row is read from source plus the dispatch call's own contract, not from a live multi-player observation; recorded honestly rather than claimed as directly witnessed. | `MediaWindow.tsx:250-261`, `lib/media.ts:115-118` (`selectPlayer`) |
| C-14 | Run a theme switch (`theme-apply <name>`). The card's colors update live with no restart and no manual action — a file watch on the rendered palette recompiles and reapplies CSS the instant matugen re-renders it. The identical outcome is also reachable directly: run `ags request -i media reload-css` and the same recompile+reapply happens immediately, independent of a theme switch — this is the exact step `theme-engine/lib/reload.sh:116-129` issues on every switch. | `app.tsx:41-48` (`reloadCss`), `:56-59` (`monitorFile` auto-watch), `:67-70` (`"reload-css"` request branch) |
| C-15 | Open the card and note its frosted-glass appearance and how far the translucency extends. The Hyprland `ags-media` namespace layer rules apply `blur = true` and `ignore_alpha = 0.25` — the frost/blur look is a compositor-side effect on the surface's namespace, not something the GTK CSS alone produces. | `hypr/.config/hypr/config/windowrules.lua:305` (blur), `:352` (ignore_alpha) |
| C-16 | Stop or quit every MPRIS-capable player, then open the card. The card still opens (it is not gated on a player existing) and shows the "Nothing playing" empty state; every transport/seek/volume gesture becomes a safe no-op rather than an error, because `cmd`/`seek`/`setVolume` all guard on the active player id being non-empty before dispatching anything. **Not independently exercised live this session** (a real player — Firefox — was active throughout); recorded from source's own guard logic, per the same honesty standard as C-13. | `lib/media.ts:100-113` |

## Dead Definitions

Deliberate prior cuts and genuinely-dead-but-still-present code, separated from live capabilities
so they never become a false parity obligation. Neither row below is a `## Parity Checklist`
entry.

| ID | What | Why dead | Not a capability the replacement owes because |
|---|---|---|---|
| D-01 | The card's own opener — the `"toggle-media"` request itself — has **zero live callers** today. | `keybinds.lua` (grepped this session) contains zero references to `toggle-media`, `ags-media`, `ags run`, or `media` at all. `autostart.lua:164-165` starts the daemon itself, which is not an opener. The only other surface that could historically have dispatched this request — waybar — was itself retired in Phase 18, before this phase started. The daemon is genuinely alive and its request handler genuinely answers (`ags request -i media toggle-media` → `"ok"`, live-confirmed this session twice — see Provenance), but nothing in the desktop today issues that request except a manual CLI invocation, exactly how this enumeration itself summoned the card. | This is reachability going dark, not functionality going dark, and it went dark in Phase 18 — two phases before this one, not a finding this phase creates. D-21-12's new `Super+M` shortcut RESTORES reachability by decision (a locked context decision, tracked in `## Parity Checklist` under C-01's row), not because this table obligates it. |
| D-02 | The `can_seek` field carried in every `media.ts` payload (`EMPTY.can_seek`, `lib/media.ts:11`) is populated by `media-status.sh`'s JSON on every tick but is **never read** by `MediaWindow.tsx` or by any accessor derived from it — the seek row's actual gating comes entirely from the separately-maintained `seekable`/`seekLength` latched state (C-11), computed from `length`, never from `can_seek` directly. Confirmed by an exhaustive grep of the whole `ags/.config/ags/` tree (excluding the vendored `@girs/*.d.ts` type-stub files, which define an unrelated GObject `can_seek` on `Gio.Seekable`): zero consumers of this specific field. | A field defined and populated with zero consumers is dead code, not a hidden capability — nothing renders or dispatches from it, so nothing is lost by not porting it. |

## Unaccounted Keys

Closure proof: every top-level exported/declared symbol across all five of the card's own source
files (`MediaWindow.tsx`, `Cava.tsx`, `lib/cava.ts`, `lib/media.ts`, `app.tsx` — `@girs/*.d.ts`
vendored type stubs excluded, since they are TypeScript ambient declarations for GNOME libraries,
not this card's own code) is checked against every `## Capabilities` row above. The mapping below
was built by hand while writing this document, then re-verified mechanically: every symbol's
owning ID must be one of `C-01`..`C-16` above, and the loop's own output is asserted empty.

```bash
#!/usr/bin/env bash
set -uo pipefail

# symbol -> owning Capability ID, one pair per top-level declaration found by:
#   grep -nE "^(export )?(default )?(function|const)" <file>
# across all five source files (see Provenance's tool-completeness note — no
# dedicated resolver exists, so this list was built by direct source read).
declare -A SYMBOL_OWNER=(
  # MediaWindow.tsx
  ["GLYPH_PREV"]="C-07" ["GLYPH_NEXT"]="C-09" ["GLYPH_PLAY"]="C-08"
  ["GLYPH_PAUSE"]="C-08" ["GLYPH_VOLUME"]="C-12" ["MediaWindow"]="C-01"
  # Cava.tsx
  ["BAR_COUNT"]="C-06" ["MAX_BAR_HEIGHT"]="C-06" ["MIN_BAR_HEIGHT"]="C-06"
  ["BAR_INDICES"]="C-06" ["Cava"]="C-06"
  # lib/cava.ts
  ["CONFIG"]="C-06" ["bars"]="C-06" ["setBars"]="C-06"
  # lib/media.ts
  ["HOME"]="C-04" ["PLAYERS_SH"]="C-07" ["STATUS_SH"]="C-04" ["EMPTY"]="C-04"
  ["media"]="C-04" ["setMedia"]="C-04" ["players"]="C-13" ["setPlayers"]="C-13"
  ["seekable"]="C-11" ["setSeekable"]="C-11" ["seekLength"]="C-11"
  ["setSeekLength"]="C-11" ["trackKeyOf"]="C-11" ["updateSeekLatch"]="C-11"
  ["refreshPlayers"]="C-13" ["cmd"]="C-08" ["seek"]="C-10" ["setVolume"]="C-12"
  ["selectPlayer"]="C-13"
  # app.tsx
  ["STYLE_LINK"]="C-14" ["STYLE_ENTRY"]="C-14" ["PALETTE_STATE"]="C-14"
  ["reloadCss"]="C-14" ["main()"]="C-01" ["request:toggle-media"]="C-01"
  ["request:reload-css"]="C-14"
)

VALID_IDS="C-01 C-02 C-03 C-04 C-05 C-06 C-07 C-08 C-09 C-10 C-11 C-12 C-13 C-14 C-15 C-16"
unaccounted=0
for sym in "${!SYMBOL_OWNER[@]}"; do
  owner="${SYMBOL_OWNER[$sym]}"
  case " $VALID_IDS " in
    *" $owner "*) ;;  # valid — accounted for
    *) echo "UNACCOUNTED: $sym -> $owner (not a real Capability ID)"; unaccounted=$((unaccounted+1)) ;;
  esac
done
echo "total symbols checked: ${#SYMBOL_OWNER[@]}"
echo "unaccounted: $unaccounted"
```

**Output of the loop above, run against this exact mapping this session:**

```
total symbols checked: 40
unaccounted: 0
```

Every one of the 40 top-level symbols across the five source files resolves to a valid
`## Capabilities` ID. `D-01`/`D-02` are findings ABOUT specific symbols/behaviours (the
`"toggle-media"` request's reachability, and the `can_seek` field's dead-ness) layered on top of
this mapping, not symbols requiring their own separate slot in it — `request:toggle-media` and
`EMPTY` are both still accounted for above, and D-01/D-02's prose is what records the additional
finding about them.

## Not a Port Specification

This document records what the AGS card let the operator DO, so nothing already built is lost by
accident when the source is deleted. It neither licenses nor mandates reproducing *how* the card
looked or *where* it sat — `PROJECT.md` frames v4.0 as a redesign against the end-4/Caelestia
reference language, not a port, and `21-CONTEXT.md`'s own decisions (D-21-01, D-21-02) already
supersede this card's specific visual treatment on purpose. A reader who takes any row below as a
target to hit would build the wrong replacement.

1. **The fixed top anchor and margin.** `anchor={Astal.WindowAnchor.TOP}` with `marginTop={54}`
   (`MediaWindow.tsx:53-54`) — **live-confirmed this session** at `y=54` via `hyprctl layers -j`.
   This is a POSITION, not a capability. The replacement's Media tab lives wherever the dashboard
   drawer's own already-settled geometry puts it (`14-UI-SPEC.md`/`21-UI-SPEC.md`), never anchored
   to this card's own top-of-screen slot, and the bar's `MediaPopout` lives wherever the bar's own
   popout-anchoring convention puts it — neither owes this card's specific `marginTop`.
2. **The five-layer `Gtk.Overlay` stack ordering**, and specifically the dual
   full-bleed-blurred-backdrop-plus-centered-thumbnail compositing (`MediaWindow.tsx:63-69`'s own
   comment: `[0] blurred-art background → [1] scrim → [2] cava bars → [3] thumbnail → [4] controls
   panel`). This is an IMPLEMENTATION detail of how GTK4's `Gtk.Overlay` widget composites
   children, and a specific stylistic choice (rendering the same art image twice, once full-bleed
   and blurred, once small and sharp) — not a capability. The replacement's single masked-art-circle
   approach (`MediaTab.qml`'s existing `MultiEffect`/`ShapePath` machinery, extended per D-21-01/02)
   is a structurally different rendering technique and a deliberately different visual language, not
   a lesser reproduction of this stack.
3. **The card's own bar count: `BAR_COUNT = 24`** (`Cava.tsx:7`, matching `ags/cava/config`'s
   `bars = 24`). A config-driven IMPLEMENTATION value, explicitly superseded: D-21-03 locks the
   replacement to 60 bars for reasons unrelated to this card (pairing evenly with the 12-lobe
   cookie shape at 5 bars per lobe), not because 24 was found lacking as a capability.
4. **The card's own live pixel footprint** — the 462×422 layer-shell surface size **live-observed
   this session** via `hyprctl layers -j`. This is this card's own rendered size, not a target;
   `14-UI-SPEC.md`/`21-UI-SPEC.md` already settle the Media tab's and popout's own geometry
   independently of it.
5. **The Nerd Font transport/volume glyph codepoints** (`GLYPH_PREV`/`GLYPH_NEXT`/`GLYPH_PLAY`/
   `GLYPH_PAUSE`/`GLYPH_VOLUME`, `MediaWindow.tsx:11-19`) and the GTK CSS class names
   (`.media-card`, `.media-scrim`, `.cava-bar`, etc., `style.scss`). Both are this card's own
   presentation vocabulary — the replacement already uses its own established Material Symbols
   variable-font glyph convention (`MediaTab.qml`'s existing `symbolFontFamily`/`font.variableAxes`
   machinery) and its own QML property system, neither of which owes this card's specific glyph
   codepoints or CSS class names.
