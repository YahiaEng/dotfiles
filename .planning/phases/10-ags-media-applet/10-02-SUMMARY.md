---
phase: 10-ags-media-applet
plan: 02
subsystem: ui
tags: [ags, astal, gtk4, gjs, typescript, jsx, layer-shell, media, sass]

# Dependency graph
requires:
  - phase: 10-01
    provides: aylurs-gtk-shell (AGS 3.1.0) + cava installed and registered in install.sh
provides:
  - "AGS v3 stow package skeleton at ags/.config/ags/ (tsconfig.json, env.d.ts, widget/)"
  - "MediaWindow() — full-screen Astal.Window name='media' namespace='ags-media', keymode ON_DEMAND, layer TOP, with centered card, click-away, Esc dismiss"
  - "app.tsx — app.start instanceName 'media' + requestHandler wiring 'toggle-media'"
  - "Human-verified proof that AGS delivers pointer clicks to widgets on this eww-0.6.0-failing / Hyprland 0.55.4 machine (the input-viability gate eww failed)"
  - "Working request form: `ags request -i media toggle-media`"
  - "Pinned AGS 3.1.0 reactive/JSX primitive names for downstream plans"
affects: [10-03, 10-04, 10-05, 10-06]

# Tech tracking
tech-stack:
  added: [dart-sass (AGS scss compile dependency)]
  patterns:
    - "AGS instance named 'media'; window name 'media'; namespace 'ags-media'; request verb 'toggle-media' — used consistently so `ags request` and `app.get_window` agree"
    - "Click-away via Gtk.GestureClick onPressed -> card.compute_bounds(win) + Graphene.Point contains_point -> win.hide()"
    - "Esc dismiss via Gtk.EventControllerKey onKeyPressed -> Gdk.KEY_Escape -> win.hide()"
    - "requestHandler matches only the exact literal 'toggle-media'; unknown requests return an inert string (no request value ever reaches a shell)"

key-files:
  created:
    - ags/.config/ags/tsconfig.json
    - ags/.config/ags/env.d.ts
    - ags/.config/ags/app.tsx
    - ags/.config/ags/style.scss
    - ags/.config/ags/widget/MediaWindow.tsx
  modified:
    - install.sh

key-decisions:
  - "Working request form is `ags request -i media toggle-media` — the bare `ags request toggle-media` FAILS (targets the default instance 'ags'). 10-06's waybar on-click MUST use the -i media form."
  - "AGS 3.1.0 uses gnim reactive primitives from the 'ags' package: createState/createBinding/createComputed/createMemo/createEffect/createConnection/createExternal/createSettings + control-flow With/For/This. No older astal 'Variable' API. Load-bearing for 10-03/04/05."
  - "dart-sass added to install.sh PACMAN_PKGS — AGS's bundler shells out to the `sass` binary to compile style.scss; without it `ags run` aborts before rendering (Rule 3 blocking deviation)."

patterns-established:
  - "AGS request verbs are matched as exact literals in requestHandler; disambiguate the instance with -i <instanceName> on the client side"
  - "AGS must launch with /usr/bin on PATH so its Go/esbuild bundler can locate the `sass` binary"

requirements-completed: [MEDIA-01]

coverage:
  - id: D1
    description: "`ags request -i media toggle-media` shows a centered dark card and a second call hides it"
    requirement: "MEDIA-01"
    verification:
      - kind: manual_procedural
        ref: "ags request -i media toggle-media -> returns 'ok'; hyprctl layers shows ags-media mapped 0 0 2560 1440; grim /tmp/ags-10-02-render.png read back shows centered card"
        status: pass
    human_judgment: false
  - id: D2
    description: "Clicking the test button prints AGS TEST BUTTON CLICKED — AGS delivers pointer input to its widgets on this machine (the eww failure this phase escapes)"
    requirement: "MEDIA-01"
    verification:
      - kind: manual_procedural
        ref: "human click test at Task 3 gate — terminal printed AGS TEST BUTTON CLICKED"
        status: pass
    human_judgment: true
    rationale: "No agent-side pointer injection exists on this machine; only a human click can prove pointer delivery to a widget. This is the phase's fail-fast gate — verified by the user, approved."
  - id: D3
    description: "Click-away (click outside the card) and Esc both hide the window"
    requirement: "MEDIA-01"
    verification:
      - kind: manual_procedural
        ref: "human test at Task 3 gate — click-away closed the window; Esc closed the window"
        status: pass
    human_judgment: true
    rationale: "Dismiss behaviour depends on live pointer/keyboard delivery to the layer surface, unverifiable without a human; confirmed by the user."

# Metrics
duration: multi-session (checkpoint-gated)
completed: 2026-07-15
status: complete
---

# Phase 10 Plan 02: AGS Scaffold + Input-Viability Gate Summary

**Standalone AGS v3 (GTK4) `media` window — centered dark card, click-away + Esc dismiss, `toggle-media` request verb — with a human-confirmed test-button click proving AGS delivers pointer input where eww could not.**

## Performance

- **Duration:** multi-session (blocked once on a missing `sass` binary, resumed after human-authorized `dart-sass` install; then paused at the Task 3 human click gate)
- **Completed:** 2026-07-15T13:13Z
- **Tasks:** 3 (2 auto + 1 human-verify gate)
- **Files created:** 5 (+ 1 modified)

## Accomplishments

- **Input-viability gate PASSED (MEDIA-01).** A human clicked the test button and the AGS terminal printed `AGS TEST BUTTON CLICKED`; click-away and Esc both dismissed the window. This is the exact capability the eww media popup lacked (`.planning/debug/resolved/eww-media-popup-clicks-dead.md`) — the entire AGS approach is now de-risked and the phase proceeds.
- Scaffolded `ags/.config/ags/` as a new stow package (tsconfig.json + env.d.ts from `ags init`, plus `widget/`).
- Authored `MediaWindow.tsx` (centered clickable card + click-away + Esc), `app.tsx` (instance `media`, `toggle-media` handler), and `style.scss` (visible dark card).
- Verified live before the human gate: `ags run` compiles with no TS/sass error; `ags request -i media toggle-media` toggles; a `grim` screenshot confirmed the centered card renders.

## Task Commits

1. **Task 1: Scaffold AGS stow package, pin reactive primitives** — `7167452` (feat)
2. **Gap fix: add dart-sass to PACMAN_PKGS** — `1181c73` (fix)
3. **Task 2: Author clickable media window** — `ff6494e` (feat)
4. **Task 3: Human-verify input-viability gate** — no commit (verification gate; APPROVED by the user)

## Files Created/Modified

- `ags/.config/ags/tsconfig.json` — TS config from `ags init` (jsx react-jsx, jsxImportSource ags/gtk4)
- `ags/.config/ags/env.d.ts` — ambient module decls for *.scss/*.css/inline imports
- `ags/.config/ags/widget/MediaWindow.tsx` — the full-screen Astal.Window + centered card + test button + click-away + Esc
- `ags/.config/ags/app.tsx` — app.start (instance `media`, css bootstrap, `toggle-media` requestHandler)
- `ags/.config/ags/style.scss` — minimal `.media-card` + `.test-btn` styling
- `install.sh` — `dart-sass` added to `PACMAN_PKGS` (AGS scss compile dependency)

## Critical Findings for Downstream Plans

### Working request form (10-06 depends on this)

**`ags request -i media toggle-media`** is the working form. The bare `ags request toggle-media` FAILS with `instance "ags" is not runnning` — it targets the default instance `ags`, not our named `media` instance. **10-06's waybar `custom/media` `on-click` MUST use `ags request -i media toggle-media`.**

### Pinned AGS 3.1.0 reactive/JSX primitives (load-bearing for 10-03/04/05)

Verified directly against the installed source at `/usr/share/ags/js/` and `gnim`'s `dist/`:

- Reactive (all from `"ags"`, re-exporting `gnim`): `createState`, `createBinding`, `createComputed`, `createMemo`, `createEffect`, `createConnection`, `createExternal`, `createSettings`. The `Accessor` returned by `createState` supports `.as(transform)`, `.peek()`, `.subscribe()`, and call-as-compute — use `media.as(m => ...)` for reactive binds.
- Control-flow JSX (also from `"ags"`): `With`, `For`, `This`, `Fragment`.
- `createPoll` from `"ags/time"`; `subprocess`/`exec`/`execAsync` from `"ags/process"`; `monitorFile` from `"ags/file"`.
- Toolkit imports: `import { Astal, Gtk, Gdk } from "ags/gtk4"`; `import app from "ags/gtk4/app"`; `import Graphene from "gi://Graphene"`.
- Astal enums (from `/usr/share/gir-1.0/Astal-4.0.gir`): `Astal.WindowAnchor.{TOP,BOTTOM,LEFT,RIGHT}`, `Astal.Exclusivity.{NORMAL,EXCLUSIVE,IGNORE}`, `Astal.Layer.{BACKGROUND,BOTTOM,TOP,OVERLAY}`, `Astal.Keymode.{NONE,EXCLUSIVE,ON_DEMAND}`.
- Widget/ref pattern: capture element refs via the `$={(self) => (ref = self)}` prop (seen used for both the window and the card).

No import-name adjustments were needed versus the approved plan's pinned code — every API in `docs/superpowers/plans/2026-07-15-ags-media-applet.md` Task 2 matched the installed 3.1.0 exactly.

### AGS needs `sass` on PATH

AGS's Go/esbuild bundler shells out to the `sass` binary at load to compile `style.scss`. Launch AGS with `/usr/bin` on PATH (e.g. `env PATH="/usr/bin:$PATH" ags run ...` when backgrounding through a restricted shell), or `ags run` aborts with `executable "sass" not found in $PATH` before rendering anything.

## Decisions Made

See key-decisions frontmatter. Durable findings: the `-i media` request form, the pinned reactive primitives, and the `dart-sass`/`sass`-on-PATH requirement.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `dart-sass` missing from the dependency list**
- **Found during:** Task 2 (first `ags run` attempt)
- **Issue:** `ags run` aborted with `executable "sass" not found in $PATH` — AGS's bundler shells out to the `sass` binary to compile `style.scss`, but neither the approved plan's Task 1 nor 10-01 listed a sass provider. Because a package install requires human legitimacy verification (slopsquat guard), this was surfaced as a package-legitimacy checkpoint rather than auto-installed.
- **Fix:** Human authorized and installed `dart-sass` (official Arch `extra` repo, `dart-sass` 1.101.2-1, `Provides: sass`, depends only on glibc). Added `dart-sass` to `install.sh` `PACMAN_PKGS` alongside `cava` to close the reproducibility gap.
- **Files modified:** `install.sh`
- **Verification:** `sass --version` → 1.101.2; subsequent `ags run` compiled `style.scss` with no error and rendered the card.
- **Committed in:** `1181c73`

**Note for future re-runs:** `docs/superpowers/plans/2026-07-15-ags-media-applet.md` Task 1 (and 10-01) still carry this omission — any fresh re-run of that plan doc should add `dart-sass` to its dependency list.

---

**Total deviations:** 1 auto-fixed (1 blocking, human-authorized package install).
**Impact on plan:** Necessary for AGS to compile its stylesheet at all. No scope creep — closes a genuine reproducibility gap for MEDIA-04.

## Issues Encountered

- The initial backgrounded `ags run` invocation surfaced the `sass`-not-found error because the AGS bundler could not locate the `sass` binary; resolved by the `dart-sass` install and by ensuring `/usr/bin` is on PATH at launch. Foreground/explicit-PATH launches compile cleanly.

## User Setup Required

None — no external service configuration. The only manual step (installing `dart-sass`) is now captured in `install.sh` for reproducibility.

## Next Phase Readiness

- MEDIA-01 foundation delivered and human-gated: AGS delivers pointer input on this machine. Ready for **10-03** (bind live MPRIS state + transport/seek/volume/switcher), which replaces the test button with the real controls and depends on the pinned reactive primitives and the `-i media` request form recorded above.

---
*Phase: 10-ags-media-applet*
*Completed: 2026-07-15*

## Self-Check: PASSED
- `ags/.config/ags/tsconfig.json` — FOUND
- `ags/.config/ags/env.d.ts` — FOUND
- `ags/.config/ags/app.tsx` — FOUND
- `ags/.config/ags/style.scss` — FOUND
- `ags/.config/ags/widget/MediaWindow.tsx` — FOUND
- `install.sh` (dart-sass) — FOUND
- Commit `7167452` — FOUND
- Commit `1181c73` — FOUND
- Commit `ff6494e` — FOUND
