---
quick_id: 260823-9ak
created: 2026-08-23T03:41:28.309Z
status: locked
source: operator-answered in-session (AskUserQuestion), 2026-08-23
---

# Context — Edge Bar

The operator specified nine requirements and then answered three blocking
ambiguities directly. Everything in this file is LOCKED. Do not re-litigate it,
do not re-derive the measurements, and do not "improve" a decision the operator
already made.

## The feature, in one line

A Caelestia-style "edge bar": two always-on strips flush to the top and bottom
screen edges that the dashboard and launcher visually attach to and animate
from. Toggleable in settings, ON by default.

## The nine requirements, as given

1. The feature is called **"edge bar"**.
2. A **settings toggle** enables/disables it.
3. **Enabled is the DEFAULT.** Disabled == exactly today's behaviour.
4. **Top and bottom edges only** — no left, no right.
5. The **dashboard** animates from the **top** edge; hovering the **centre of
   the top edge** opens it.
6. The **launcher** (Super+Space and Super-tap) animates from the **bottom**
   edge; hovering the **centre of the bottom edge** opens the Super-tap **menu**
   mode.
7. The **attached corners** — where the surface meets the edge strip, left and
   right — must be **smooth like Caelestia's**: a concave flare, not a hard 90°.
   **This applies in BOTH edge-bar mode and regular mode.**
8. The strip is **thicker at the spawn location**.
9. The edge bar **follows the shifting colour scheme** like every other surface.

## Locked decisions

### D-1 — "App drawer" means the DASHBOARD
Operator-answered. Requirement 5's "app drawer" is `modules/Dashboard.qml`,
which this repo already calls the "dashboard drawer" (`keybinds.lua:246`,
Super+D). It is **not** a new all-apps grid and **not** the notification centre.

### D-2 — The edge bar is an INDEPENDENT FRAME
Operator-answered, and this is the Caelestia-faithful shape: Caelestia's border
is a separate always-on surface with the bar living inside it.

- The edge bar is **two NEW surfaces** — a top strip and a bottom strip.
- The existing bar is **NOT absorbed, NOT moved, NOT reoriented**.
- **`Bar.qml` must stay untouched.**
- It must work in **both** bar orientations.

Load-bearing fact behind this: the operator's live bar orientation is
`vertical` (right edge) — `~/.local/state/quickshell/bar-orientation` reads
`vertical`. A top+bottom edge bar therefore **cannot** be the bar, and any plan
that tries to make it the bar has misread this decision.

### D-3 — The extra thickness is a STATIC bulge
Operator-answered. Requirement 8's extra thickness is a **permanent** bulge at
the centre of each edge — a discoverable landmark that shows you where to hover
even when nothing is open. It is **not** a hover-reactive or open-reactive
swell. No new motion curve is needed for it.

### D-4 — Each strip reserves its own space
Decided by the assistant; flag it only if you find contrary evidence.

Each strip sets `exclusiveZone` = its own thickness, so tiled windows do not
paint over an always-on strip. Follow `Bar.qml:105-120`'s warning **exactly**:
Hyprland's reservation TOTAL is `margins.<edge> + exclusiveZone`, so a margin
must never be folded into both terms. That double-count bug has already been
reproduced twice in this repo (18-01 and 18-05), each time as a +6 signature.

### D-5 — The launcher's DIRECTION is mode-branched; the CORNER SHAPE is not
Decided by the assistant, derived from the operator's own requirements 3, 6
and 7.

- **Direction** (req 6 + req 3): bottom-anchored in edge-bar mode,
  top-anchored — today's behaviour — when the toggle is off.
- **Corner shape** (req 7): **not** branched. It applies in both modes, because
  the operator said so explicitly.

## Measured ground truth

Verified in-session on 2026-08-23 against the live tree and the live host.
Quote these; do not re-derive them.

| Claim | Evidence |
|---|---|
| The bar is NOT an edge today — it floats inset | `Bar.qml:79-84` — `margins.top: Design.barEdgeMargin` (6), `margins.left/right: Design.barSideMargin` (10) |
| The bar has exactly TWO orientations | `BarEntryModel.qml:63-69` — horizontal (top) \| vertical (right) |
| Live orientation is vertical | `~/.local/state/quickshell/bar-orientation` = `vertical` |
| Req 5 is LARGELY ALREADY BUILT | `Dashboard.qml:222-225` all four anchors true, `:253-254` `margins.top: 10`, `y: opened ? 0 : -height`. Only the hover trigger and the corner smoothing are new |
| Req 6 is a REVERSAL | `Launcher.qml:87-91` uses the same top-drop posture (`drawerTopMargin: 10`); `Launcher.qml:461` `y: opened ? 0 : -height` |
| Req 7's exact target | `Launcher.qml:488-491` and `Dashboard.qml:644-645` both set `topLeftRadius: 0` / `topRightRadius: 0` / `bottomLeftRadius: 28` / `bottomRightRadius: 28`. `cornerRadius: 28` at `Launcher.qml:118` and `Dashboard.qml:386` |

### Req 7 is the hardest item, and it is NOT a radius change

`GradientBorder` rides the **same** radii (`Launcher.qml:499-507`,
`Dashboard.qml:677`) and is a `Shape`/`ShapePath` component. A concave flare
needs **new path geometry** in the border, not a new number. Budget for it —
this is novel technique in this repo.

`Shape`/`ShapePath` precedent to copy from:
`modules/dashboard/GradientBorder.qml`, `modules/dashboard/Dial.qml`,
`modules/bar/MediaPopout.qml`, `modules/dashboard/DashboardTab.qml`,
`modules/dashboard/MediaTab.qml`, `modules/notifications/NotifCard.qml`,
`modules/overview/WorkspaceTile.qml`.

### Reusable precedent

- **Hover reveal** — `modules/bar/HotZone.qml` is an invisible input-only
  `PanelWindow` + `HoverHandler`. Reuse its shape. Two caveats: today it mounts
  only while the bar is HIDDEN (LazyLoader keyed on the inverse of bar
  visibility), and it is **deliberately click-inert** per threat T-18-16-01 —
  read that threat before adding any click handler.
- **Settings toggle** — `Prefs.qml` carries a CLOSED key allowlist
  (`_allowedKeys`) plus hardcoded `_defaults` keyed by the same dotted path.
  Add the key to **both** arrays in the **same** commit, then one `ToggleRow`
  (`modules/settings/common/ToggleRow.qml`) on a settings page. Existing bar
  keys live under `bar.*` (`bar.autoHideOnIdle`, `bar.capsules.*`,
  `bar.tray.iconTint`).
- **Prefs is `watchChanges: false`** — a LIVE shell will NOT see a hand-edit to
  `prefs.json`. Round-trip through `setValue()` or restart the shell.
- **Keybinds already exist; no new binds needed** — `keybinds.lua:97`
  Super+Space → `quickshell:launcher`; `:98` Super+R → `quickshell:launcher`;
  `:99` Super tap → `quickshell:launcher-menu` (a DISTINCT GlobalShortcut);
  `:246` Super+D → `quickshell:dashboard`.
- **Namespace/blur** — any surface named `^quickshell-.*` inherits
  `windowrules.lua`'s family blur rule with an `ignore_alpha` **0.5 floor**
  (`windowrules.lua:397/449`). No fill may sit below 0.5 alpha or blur dies
  silently. Per-surface layer rules must come AFTER the family regex, and
  `hyprctl reload` DROPS layer-rule edits — use `hyprctl eval` or a restart.
- **Req 9 is nearly free if built right** — read palette values from
  `modules/Colours.qml`. `colour-lint` (GATE-04) rejects hardcoded colours in
  QML; `motion-lint` enforces `Motion.qml` tokens.

## Verification cautions carried in from prior tasks

- A green gate only proves what it can see. `colour-lint` once read 202/0 while
  18 unthemed tooltips shipped.
- Three green lint gates **cannot** see a bad QML import. After any QML edit,
  restart and read `~/.cache/quickshell.log` **below the last start marker**.
- Declare QML members before construction-time use, or you get
  "is not a function" plus a plausible wrong fallback.
- `motion-lint` verifies a site reads a TOKEN rather than a literal; it does
  **not** verify the token EXISTS. An undeclared singleton property resolves to
  `undefined` and Qt silently falls back to 250ms. Verify any new token
  RESOLVES.
- **Never** spawn `qml6` probe scripts — each opens a real window and a loop of
  them takes the session down. `grim -g` on a layer surface IS safe here.
- No click-injection tool exists on this host; hand interactive hover checks to
  the operator.
- `shell.qml` line 1 is `//@ pragma UseQApplication` — SHELL-WIDE, required for
  DBusMenu. Do not remove it.

## Suggested sequencing

1. **Corner geometry (req 7)** first, as a standalone tracer on ONE surface —
   it is the novel technique and it lands in both modes regardless of the
   toggle.
2. **Edge strips + Prefs toggle** (reqs 1, 2, 3, 4, 8, 9).
3. **Hover triggers** (reqs 5, 6).
4. **Launcher direction branch** (req 6 + D-5).
