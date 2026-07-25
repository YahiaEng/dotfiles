# Phase 7: Super-Key Menu - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-13
**Phase:** 7-Super-Key Menu
**Areas discussed:** Super-tap vs launcher, Menu engine & navigation, Power menu overlap, Cheat-sheet form, AI dashboard, Game center, Settings submenu, Root menu shape, Menu theming, Keybind regression, Package gating, Launch convention, Utilities content, Network tool, Picker transitions, Gaming-mode state

---

## Super-tap vs launcher

| Option | Description | Selected |
|--------|-------------|----------|
| Apps are a menu entry | Super-tap opens menu only; "Apps" becomes a root entry (one extra keystroke to launch) | |
| One fused surface | Apps + menu entries searchable together in one walker list | |
| Launcher moves to Super+Space | Super-tap = menu (pure hierarchy); launcher gets its own dedicated bind | ✓ |

**User's choice:** Launcher moves to Super+Space
**Notes:** Keeps both surfaces clean and distinct; closest to how Omarchy separates launcher from menu. Existing `bind = $mainMod, SUPER_L, exec, walker` is replaced, not shared.

---

## Tap fidelity (Hyprland has no native bare-modifier-tap bind)

| Option | Description | Selected |
|--------|-------------|----------|
| True tap-only, researched | Researcher must find and prove a real tap-only mechanism with a full regression sweep; may pull in a new package | ✓ |
| Best-effort, fall back to a chord | Try tap-only; fall back to a documented chord with evidence if it can't be made non-destructive | |
| Skip the tap, use a chord | Bind the menu to a deliberate chord from the start; zero regression risk | |

**User's choice:** True tap-only, researched
**Notes:** User took the hardest, highest-fidelity option — the phase is named after the tap, so descoping it was rejected. This is the phase's headline risk.

---

## Keybind safety net

| Option | Description | Selected |
|--------|-------------|----------|
| Kill-bind + TTY procedure | Reserved never-shadowed escape bind AND the Phase 4-style second-TTY recovery procedure as a launch requirement | ✓ |
| Test in a nested session | All Super-bind experiments in a nested Hyprland instance | |
| Kill-bind only | Just the escape bind | |

**User's choice:** Kill-bind + TTY procedure
**Notes:** Mirrors the Phase 6 hyprlock lockout-recovery mandate (06-CONTEXT D-14). Paired deliberately with the aggressive tap-only choice above.

---

## Menu engine

| Option | Description | Selected |
|--------|-------------|----------|
| Provider, dmenu fallback | Prefer the native menus provider, but spike it FIRST; fall back to the proven dmenu chain if it can't express submenus/actions/icons | ✓ |
| Elephant menus provider | Commit to the declarative provider now | |
| Bash + walker --dmenu chain | Script each menu level; zero unknowns, hand-rolled back-navigation | |

**User's choice:** Provider, dmenu fallback
**Notes:** User initially leaned toward committing to the provider outright, then asked for recommendations and switched. Deciding argument: Phase 4 shipped dead hyprlock config because an installed binary silently rejected unknown options — PROJECT.md's Key Decision is literally "verify against the installed binary schema before relying on it." Six submenus + the cheat-sheet hang off this choice.

---

## Navigation

| Option | Description | Selected |
|--------|-------------|----------|
| Drill-down in place | Same window swaps to submenu; Esc/Backspace back; breadcrumb in placeholder | ✓ |
| Drill-down with global search | Both drill-down and root-level fuzzy match across all leaf actions | |
| Flat + searchable everything | Root shows groups; typing searches all leaves at once | |

**User's choice:** Drill-down in place
**Notes:** Cross-submenu global search is a bonus if walker's matcher gives it free — explicitly NOT a requirement, since it's the most likely thing the provider can't express.

---

## Icons

| Option | Description | Selected |
|--------|-------------|----------|
| Nerd Font glyphs | Consistent with Phase 6 D-10; CSS-themed, no assets, decoupled from the icon-theme picker | ✓ |
| Icon-theme names | Follows the Phase 6 icon-theme picker; richer/colourful but couples the menu to the icon axis | |

**User's choice:** Nerd Font glyphs
**Notes:** Deciding argument: icon-theme names would mean switching Papirus→Tela could silently blank menu icons.

---

## Power menu overlap

| Option | Description | Selected |
|--------|-------------|----------|
| Launches wlogout | Power fires the existing wlogout.sh; one power surface; Phase 9's wleave swap becomes invisible to the menu | ✓ |
| Inline walker list | Power drills into a walker submenu calling systemctl/hyprshutdown directly | |
| Inline list, retire wlogout | Drop wlogout entirely, cancelling Phase 9 | |

**User's choice:** Launches wlogout
**Notes:** Avoids duplicating power-action logic and preserves Phase 6's WLOG-01 center-bar design.

---

## powermenu.sh cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Delete it | Unbound, unreferenced, already drifted (no hibernate; duplicate hyprshutdown calls) | ✓ |
| Keep as fallback | Emergency power path if wlogout breaks | |

**User's choice:** Delete it
**Notes:** v1.0 precedent for removing dead configs; keeping it recreates the "duplicated orchestrators" problem.

---

## Cheat-sheet form

| Option | Description | Selected |
|--------|-------------|----------|
| Walker searchable list | Parsed binds in a walker list; cheapest thing that satisfies MENU-07 | |
| fzf-in-floating-kitty table | Formatted, column-aligned, section-grouped table; better for browsing | |
| Both surfaces | Walker list for quick lookup + a "View all" kitty table | ✓ |

**User's choice:** Both surfaces
**Notes:** Must share one parser so the two surfaces cannot diverge.

---

## Bind labels

| Option | Description | Selected |
|--------|-------------|----------|
| Comments + backfill | Parse trailing `# comments` and backfill descriptions onto every bind lacking one; keybinds.conf stays the single source of truth | ✓ |
| Comments only, skip the rest | Only commented binds appear; ~half the binds silently vanish | |
| Separate descriptions file | Side-car bind→description map | |

**User's choice:** Comments + backfill
**Notes:** Side-car rejected as the exact drift pattern this project keeps removing. Phase 6 already wrote its binds with descriptions, anticipating MENU-07.

---

## Cheat-sheet generation

| Option | Description | Selected |
|--------|-------------|----------|
| Live on open | Parse keybinds.conf each time; can never drift | ✓ |
| Rendered at theme/install time | Cached; marginally faster but introduces a staleness class | |

**User's choice:** Live on open

---

## AI dashboard — launchers

| Option | Description | Selected |
|--------|-------------|----------|
| Web apps via Zen | Claude/ChatGPT/Gemini/Perplexity as dedicated windowrule'd Zen windows; zero new packages, already pipeline-themed | ✓ |
| Claude Code / CLI agents | A kitty window running an AI CLI/TUI agent | ✓ |
| Local models (ollama) | ollama + a local chat UI; offline, uses the RTX 3070 | ✓ |
| Native desktop clients | AUR electron wrappers | |

**User's choice:** All three except native desktop clients
**Notes:** Native AUR electron wrappers rejected as a supply-chain/maintenance liability for something a browser tab does.

---

## Ollama depth

| Option | Description | Selected |
|--------|-------------|----------|
| Ollama + TUI chat | ollama + a terminal chat client; no web server, no Docker, kitty-themed | ✓ |
| Ollama + open-webui | Full local web UI; Python/Docker-class dependency, unthemeable by the pipeline | |
| Ollama service only | Just `ollama run` in kitty | |

**User's choice:** Ollama + TUI chat

---

## Model auto-pull

| Option | Description | Selected |
|--------|-------------|----------|
| No auto-pull | install.sh installs/enables ollama but pulls nothing; keeps the container gate unattended | ✓ |
| Pull a small default model | Works out of the box; costs GBs on every fresh install | |

**User's choice:** No auto-pull

---

## Web AI surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| Claude | claude.ai as a dedicated Zen window | ✓ |
| ChatGPT | chatgpt.com | ✓ |
| Gemini | gemini.google.com | ✓ |
| Perplexity | perplexity.ai | ✓ |

**User's choice:** All four

---

## AI workspace

| Option | Description | Selected |
|--------|-------------|----------|
| Named workspace + auto-layout | Reserved workspace + windowrules; menu switches to it and launches what isn't running; idempotent | ✓ |
| Special/scratchpad workspace | Toggleable overlay like the existing Super+S magic scratchpad | |
| Just a layout, no reserved workspace | Tiles AI apps on the current workspace | |

**User's choice:** Named workspace + auto-layout
**Notes:** Must be idempotent — picking it twice yields one set of windows, not two.

---

## Game center — apps

| Option | Description | Selected |
|--------|-------------|----------|
| Steam | multilib; named explicitly in the requirement | ✓ |
| Lutris | Non-Steam / Wine / emulator management | ✓ |
| Heroic (Epic/GOG) | AUR; falls under the package-legitimacy gate | ✓ |
| ProtonUp-Qt | Manages Proton-GE / Wine-GE versions | ✓ |

**User's choice:** All four
**Notes:** Steam needs multilib explicitly enabled in install.sh.

---

## Gaming extras

| Option | Description | Selected |
|--------|-------------|----------|
| Launchers only | Matches MENU-04's exact wording; a gaming-mode toggle is a different capability | |
| Add a gaming-mode toggle | Kills eye-candy, inhibits idle/lock, enables gamemode | ✓ |

**User's choice:** Add a gaming-mode toggle
**Notes:** Claude flagged this as arguably new desktop behaviour rather than menu wiring; user took it anyway, so scope was bounded tightly in the follow-up below.

---

## Gaming mode scope

| Option | Description | Selected |
|--------|-------------|----------|
| Hyprland eye-candy off | Blur/animations/shadows/rounding off via `hyprctl keyword` at runtime only | ✓ |
| Idle/lock inhibit | Prevent hypridle/hyprlock firing mid-game | ✓ |
| gamemode + mangohud | Feral gamemode + FPS overlay; wired into launch commands, not global state | ✓ |
| Waybar hide | Hide waybar while gaming | ✓ |

**User's choice:** All four
**Notes:** Claude flagged the waybar-hide risk — Phase 8 reworks waybar entirely — and it was accepted on condition it be built as a thin, re-pointable call rather than a bespoke hiding mechanism. Config-file rewriting is forbidden; runtime `hyprctl keyword` only.

---

## Gaming mode surface

| Option | Description | Selected |
|--------|-------------|----------|
| Menu toggle + notification | Toggle entry, notification, state file so the entry can show current status; no waybar dependency | ✓ |
| Menu toggle only | Toggles silently | |

**User's choice:** Menu toggle + notification

---

## Gaming mode state persistence

| Option | Description | Selected |
|--------|-------------|----------|
| Reset to OFF on session start | Session-scoped; a fresh session always starts with the full theme intact | ✓ |
| Persist across reboots | State survives; autostart re-applies it | |

**User's choice:** Reset to OFF on session start
**Notes:** Forecloses the "mysteriously ugly desktop with no memory of why" failure mode.

---

## Settings submenu contents

| Option | Description | Selected |
|--------|-------------|----------|
| Bluetooth | blueman / overskride | ✓ |
| Audio (pavucontrol) | Mixer; complements Phase 6 SwayOSD | ✓ |
| Display / monitors | nwg-displays writes Hyprland monitor config directly | ✓ |
| Waybar layout switch | Reuses the existing waybar-switch.sh | ✓ |

**User's choice:** All four (on top of the named theme/wallpaper/network)

---

## Picker home (icon theme, nerd font)

| Option | Description | Selected |
|--------|-------------|----------|
| Appearance under Settings | Utilities = things you DO; Settings = things you CONFIGURE | ✓ |
| All six under Utilities | Matches MENU-02's literal wording | |
| Both — cross-listed | Duplicate entries in both submenus | |

**User's choice:** Appearance under Settings
**Notes:** Knowingly overrides MENU-02's literal wording, which lists icon theme and font switcher as utilities.

---

## Root menu shape

| Option | Description | Selected |
|--------|-------------|----------|
| Six groups, task-frequency order | The six requirement entries, Power last (destructive, shouldn't sit under the default cursor) | ✓ |
| Six groups + pinned quick actions | Plus 2-3 flat direct actions at the top | |

**User's choice:** Six groups, task-frequency order

---

## Menu theming

| Option | Description | Selected |
|--------|-------------|----------|
| Same walker theme | Reuses the existing `rice` theme / walker-style.css (already contract target #18); zero new targets, zero new parity fixtures | ✓ |
| Dedicated menu theme | A separate walker skin; prettier but a 19th contract file needing light+dark parity across 22 palettes | |

**User's choice:** Same walker theme

---

## Keybind regression proof

| Option | Description | Selected |
|--------|-------------|----------|
| Scripted sweep + manual pass | Rerunnable checker parses keybinds.conf, asserts every bind registers in `hyprctl binds`, flags shadowing; plus a human pass | ✓ |
| Manual checklist only | Human presses every Super+key once; unrepeatable | |

**User's choice:** Scripted sweep + manual pass
**Notes:** Matches the theme-doctor / theme-parity posture. Phase 8 and 9 both touch binds again and inherit this gate.

---

## Package gating

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 4/6 precedent | Official repos preferred; every AUR package gets a human legitimacy check at execution time; multilib handled explicitly for Steam | ✓ |
| Auto-add, review after | Planner adds them all; review the diff | |

**User's choice:** Phase 4/6 precedent

---

## Launch convention

| Option | Description | Selected |
|--------|-------------|----------|
| uwsm app -- everywhere | Every GUI launch from the menu goes through `uwsm app --`, like keybinds.conf | ✓ |
| Bare exec | Menu entries exec directly | |

**User's choice:** uwsm app -- everywhere
**Notes:** Preserves systemd scope isolation — what makes `uwsm stop` and the power actions clean.

---

## Utilities submenu contents

| Option | Description | Selected |
|--------|-------------|----------|
| Screenshot as a sub-submenu | Utilities = Screenshot › (region/window/full/record), Emoji, Colour, Clipboard | ✓ |
| Flat — all seven entries | No nesting; long list dominated by capture | |
| Just 'Screenshot' → region | One entry firing region capture; other variants keybind-only | |

**User's choice:** Screenshot as a sub-submenu

---

## Network tool

| Option | Description | Selected |
|--------|-------------|----------|
| nmtui in floating kitty | The Phase 5/6 floating-kitty pattern; kitty-themed, no new GUI package | ✓ |
| nm-connection-editor / GUI | The GTK NetworkManager GUI | |
| impala / iwd TUI | Nicer Wi-Fi TUI, but implies a network-stack change | |

**User's choice:** nmtui in floating kitty

---

## Picker transitions (walker → floating kitty)

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse the pickers as-is | Menu closes, kitty picker opens — same as the keybind does today; keeps kitty-graphics previews | ✓ |
| Rebuild them as walker submenus | Seamless single-surface feel, but loses the previews and duplicates working code | |

**User's choice:** Reuse the pickers as-is
**Notes:** "The menu is a launcher for the pickers, not a replacement." A wallpaper picker with no thumbnails is a downgrade.

---

## Claude's Discretion

- Root menu ordering (within "six groups, Power last"); exact entry wording; exact Nerd Font glyph per entry.
- Ordering of entries within each submenu.
- Ollama TUI chat client choice (official repo preferred); bluetooth manager choice (blueman vs overskride).
- AI workspace number and window layout (must not collide with Super+1..0; must be idempotent).
- The exact tap-only mechanism, chosen on research evidence — including whether it warrants a new package.
- The reserved kill-bind's exact chord; the Super+Space launcher bind's exact form.
- Cheat-sheet table formatting/grouping; the shared parser's implementation.
- Gaming-mode state-file location and notification wording.
- Whether the menu definitions live in one file or several.

## Deferred Ideas

- Waybar gaming-mode indicator — Phase 8 (state file left as the probe, as Phase 6 did for the recorder).
- Global cross-submenu search — bonus if walker's matcher gives it free; not a requirement.
- A dedicated walker menu skin — rejected on drift/parity cost; revisit if the shared theme proves inadequate.
- open-webui / a local web AI UI — rejected as an unthemeable Python/Docker-class dependency.
- Auto-pulling a default ollama model on install — rejected to keep the container gate unattended.
- Native AI desktop clients (AUR electron wrappers) — rejected as a supply-chain/maintenance liability.
- Pinned flat quick-actions at the menu root — rejected; each already has a keybind.
