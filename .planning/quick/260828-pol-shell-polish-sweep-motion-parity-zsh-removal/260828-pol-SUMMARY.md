---
quick_id: 260828-pol
slug: shell-polish-sweep-motion-parity-zsh-removal
date: 2026-08-28
status: complete
commits: [480ef976, a0288c4e, b415bd58, 813e7542, 3756f8b9, 8b74c021]
related: [260828-u0r]
---

# Quick Tasks 260828-nav / -mot / -zsh / -pol — SUMMARY

Six of the seven operator-requested tasks in one session (the seventh, the
colour-role expansion, is `260828-u0r` and had to land first — two of these
depended on it).

## 1. Settings sections + scrolling + scrollbar (`480ef976`)

**The sections already existed and had since they were written.** `NavRail.qml`
computed `isCategoryStart`/`isCategoryEnd` and set corner radii from them. It
was invisible because unselected rows were painted
`Qt.alpha(Colours.secondaryContainer, 0)` — fully transparent. **A corner
radius needs a fill to be seen.** The tonal ladder that makes a real filled
pill possible only landed in `260828-u0r`, immediately before this.

Rows now fill `surfaceContainerHigh` (`Highest` on hover), category boundaries
add a top gap, and the icon becomes a circular chip — matching Caelestia's
`navpane/NavLocations.qml`, which likewise carries **no section header text**.
Verified by screenshot: appearance / connectivity / display / shell now read as
four distinct groups.

`ThemedScrollBar` added at `modules/` root (ThemedToolTip's precedent).
Deliberately not QQC2's `ScrollBar` — that is a Control in colour-lint's
documented blind spot; this is a Rectangle pair driven off the Flickable's own
`visibleArea`, 4px at rest / 8px on hover, hidden when content fits. Wheel now
moves a fixed pixel step with an animated `contentY`.

**Two placement traps, both measured:**
- A Flickable's default property appends Item children to its *scrolled*
  `contentItem`, so a bar declared inside travels with the content.
- QML anchors resolve only against a parent or **sibling**. NavRail's Flickable
  sits one level deeper than the bar could reach — logged "Cannot anchor to an
  item that isn't a parent or sibling" and rendered nothing. A `flickHost`
  wrapper gives them a common parent. `PageBase` needed none; there they were
  already siblings.

Also: `ThemedScrollBar` first shipped with `import "../"`, which from
`modules/` points *above* the module and **took the whole shell down at
startup**. That incidentally proved settings pages are **not** lazily resolved
— `PageCompRegistry` pulls `AppearancePage` → `PageBase` eagerly at config
load, so it was a hard startup error, not a deferred one.

## 2. Update glyph tooltip removed (`a0288c4e`)

Two lines. The seam is left declared: its empty default is what keeps the
`Readout` hover handler disabled, and that gating is load-bearing for QBAR-09's
dwell path. It now has no consumer.

## 3. Motion parity for the four non-zen styles (`b415bd58`)

Zen overrode 4 easings / 8 semantic names / **13** Hyprland leaves. The others
overrode 1–2 / 6 / **2–4**. Switching away from zen dropped **nine** leaves
back to base MD3, so each style's character stopped at the window border.

All four now carry 8 semantic entries and all 13 leaves, plus
`spatial-out`/`spatial-move`/`effects` overrides. Each keeps its identity:
smooth glides on slide/slidefade at long durations, snappy pops at
short3/short4, bouncy keeps its crest-and-snap-back, wavy swells on
slidefadevert. Three base leaf speed channels added (`leaf-short3`,
`leaf-short4`, `leaf-medium1`) — snappy and bouncy needed leaves faster than
the existing `leaf-medium2` floor.

**Invariants verified programmatically, not assumed:** only `spatial-*` leave
[0,1] (`effects` drives colour and stays monotonic in all six styles); no
control point exceeds Hyprland's 2.00 cap, above which the compositor silently
keeps the *old* curve; every leaf curve resolves to a **four**-number easing
(`emphasized` is ten and QML-only); every `speed_key` resolves.

**Proven live:** switched to `smooth` and read the compositor back — all 13
leaves overridden on Hyprland where this style previously reached 4. Restored
to zen.

## 4. zsh removed entirely (`813e7542`)

Operator chose full removal over two narrower options. Reverses D-08/D-12,
which kept zsh as the login shell for TTY recovery; bash remains the fallback.

**One real dependency caught before deleting anything:** the `zshell` package
also shipped `~/.config/oh-my-posh/`, and fish's `config.fish` sources
`catppuccin.omp.json` from it. Deleting `zshell/` outright would have silently
broken fish's **prompt**. Moved (`git mv`) into the `fish` package, its actual
consumer; verified the link resolves and `oh-my-posh init fish` succeeds.

**A gate blind spot this exposed, fixed rather than left:** emptying
`ALLOWED_HOME_DOTFILES` took `stow-link-check` from 2 checks to 1, because a
declared sweep root yielding zero links emitted **nothing at all**. A gate that
quietly reports one fewer check is indistinguishable from a gate that lost
coverage. Added an `[EMPTY]` verdict — which immediately showed **three other**
roots had also been silently contributing nothing. All three verified
legitimately symlink-free. Self-test still 6/6.

**Two privileged steps remain for the operator** (sudo needs a password here),
and **order matters**:
1. `chsh -s /usr/bin/fish aorus`
2. `sudo pacman -Rs zsh`

`zsh` is *Required By: None* (Optional For: fzf, kitty-shell-integration).

## 5. Scroll indicators across the shell (`3756f8b9`)

Enumerated with a **parser**, not a grep: 26 files instantiate a
Flickable/ListView/GridView at a declaration position; **21 had no indicator**.
This corrected the "39 files / 3" figure quoted in `480ef976`, which came from
a grep that also counts the words in comments and property types.

19 bars across 18 files. Two surfaces deliberately left alone and stated:
`NotifPopupStack` (transient popups), and Launcher's apps-mode ListView — it is
the **root of a `Component`**, which holds exactly one item, so a sibling bar is
a hard parse error (measured: the first attempt took the shell down with
"Invalid component body specification"). Wrapping it would change what
`resultsLoader.item` *is*, and Launcher duck-types that object's `activate()`.

Verified by **exercising** every lazily-loaded surface against a restarted
shell — five launcher modes, settings, the notification centre, all eight bar
popouts, the appearance and packages windows.

## 6. Three pre-existing defects the sweep surfaced (`8b74c021`)

All attributed by re-running the same probe against a **stashed** tree — none
is fallout from this session's changes.

**a. Icon previews broken for the three largest themes — the real one.**
Papirus, Papirus-Dark and Papirus-Light read `0/0` forever and rendered no
preview. Measured the probe script per theme: Adwaita **136ms**, elementary
**1.1s**, but Papirus **6.4s**, Papirus-Dark **6.9s**, Papirus-Light **6.8s**.
The watchdog killed at **5000ms**. The killed process exits non-zero,
`onExited` caches `[]` for *any* non-zero exit, and `previewFor()` re-queues
only on a cache **miss** — so one timeout poisoned the entry permanently and
stalled the rail behind it. Watchdog raised to 15s (>2× measured worst case) on
both preview queues; a kill now logs a warning, because a silent kill is
indistinguishable from a theme with no icons, which is exactly how this hid.
**Verified: all eight themes resolve, Papirus 12/12, and the detail pane
renders the Papirus folder icon for the first time.**

**b. Binding loops** in `AtIconsTab` (`_rows`, `_diffRows`, `_coverage`).
`previewFor()`/`diffPreviewFor()` are called *from bindings* and, on a cache
miss, queue a fetch that mutates properties those bindings depend on — a
binding that writes what it reads. Both queue calls now go through
`Qt.callLater`. Measured side benefit: at 18s the old code had resolved 3 of 8
themes, the fixed code 5 of 8 — the loop was throttling the queue too.

**c. Null dereference** in `SectionPopout` on teardown, reproduced by cycling
all eight bar popouts. A QML `id` naming a destroyed object evaluates to null.
Guarded at both sites.

## Final gate state

quickshell-doctor **28/0** · theme-doctor **1575/0** · theme-parity **1897/0**
· keybind-doctor **13/0** · hypr-equivalence-check **PASS 3 / FAIL 0** ·
colour-lint 572/0 · singleton-prop-check 0 · qml-import-check 0/192 ·
motion-lint 811/0 · transparent-lint 193/0 · button-lint 9/0 ·
settings-index-check 191/0 · stow-link-check 1/0 (+4 EMPTY) with self-test 6/6.

## Operator checklist — what I could not do from here

1. `chsh -s /usr/bin/fish aorus`, then `sudo pacman -Rs zsh` (in that order).
2. Judge the new motion styles by feel — switch through smooth/snappy/bouncy/
   wavy in Settings and watch window open/close, workspace switch, and the bar
   popouts. The leaf coverage is proven live; whether each *feels* right is a
   taste call.
3. Drag a scroll bar handle. Rendering and position are pixel-verified, but
   there is no input-injection tool on this host for layer surfaces.
