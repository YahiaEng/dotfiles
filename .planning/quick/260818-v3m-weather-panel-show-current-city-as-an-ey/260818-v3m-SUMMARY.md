---
quick_id: 260818-v3m
phase: quick
plan: 260818-v3m
subsystem: quickshell-dashboard-weather
tags: [quickshell, qml, weather, geocoding, dashboard]
status: complete
dependency-graph:
  requires:
    - modules/dashboard/WeatherBackend.qml (Phase 14 Plan 07)
    - modules/dashboard/WeatherTab.qml (Phase 14 Plan 07/09/10)
    - modules/dashboard/qmldir (Phase 14 Plan 03, frozen manifest)
  provides:
    - modules/dashboard/GeocodeBackend.qml (second fenced host)
    - WeatherBackend.cityLabel / cityLabelSource
  affects:
    - modules/dashboard/WeatherTab.qml (hero eyebrow)
tech-stack:
  added:
    - "Nominatim reverse-geocode (nominatim.openstreetmap.org/reverse)"
  patterns:
    - "one-host-per-fenced-file (was one-host-repo-wide)"
key-files:
  created:
    - quickshell/.config/quickshell/modules/dashboard/GeocodeBackend.qml
  modified:
    - quickshell/.config/quickshell/modules/dashboard/qmldir
    - quickshell/.config/quickshell/modules/dashboard/WeatherBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/WeatherTab.qml
decisions:
  - "cityOverride/onCityChanged routes through the existing _revalidateAgainstSettings() chokepoint rather than calling _resolveCityIfNeeded() directly, resolving a contradiction between the plan's prose (b) and its mechanical verify block + explicit 'no third call site' rule in (d) — the count-3 grep is authoritative."
  - "Added GeocodeBackend.abort() (not in the plan's Task 1 property/function list) so a coordinate-change mid-flight can cancel a stale in-flight request before it resolves against the new coordinates' cache — Rule 2 (missing critical correctness behaviour)."
  - "Eyebrow glyph uses Colours.primary (a themed role, not WeatherPalette — that singleton's documented single-consumer scope is intentionally not widened here)."
metrics:
  duration: "~45min"
  completed: 2026-08-18
actuals:
  tokens: 5901
  tasks: 3
  commits: 3
---

# Quick Task 260818-v3m: Weather hero eyebrow — current city as an eyebrow, reverse-geocoded once per coordinate change — Summary

Added a second fenced host (`GeocodeBackend.qml`, Nominatim reverse-geocode) driven by `WeatherBackend.qml`'s existing coordinate-change invalidation, published as `cityLabel`/`cityLabelSource` (override → geocoded → timezone → hidden), and rendered as an uppercase city eyebrow above the temperature in `WeatherTab.qml`.

## What Was Built

**Task 1 — `GeocodeBackend.qml` (new file).** A `Scope`-rooted, non-visual backend mirroring `WeatherBackend.qml`'s structure and comment discipline. Its `resolve()` entry point is gated on `drawerOpen` + `coordsValid` + `!requestInFlight`, builds a Nominatim reverse-geocode URL (`lat`, `lon`, `format=jsonv2`, `zoom=10`, `accept-language=en` — load-bearing, verified live to avoid the local-language name), sends a descriptive `User-Agent` header, and emits `resolved(city)` after an explicit shape check (`address.city` → `address.town` → `address.village` → `name`, first non-empty wins). Registered in `modules/dashboard/qmldir` as the fifteenth type, in the same commit that created it. It is the only `.qml` file repo-wide naming the Nominatim host — the fence is now "one host per fenced file," verified by a repo-wide grep in the same commit.

**Task 2 — `WeatherBackend.qml` resolution chain, cache, and corrected fence.**
- Corrected the header comment that used to assert no location lookup existed anywhere in the tree; it now states the reversal plainly, names the quick task, and cross-references the sibling's privacy/rate-policy note without repeating the literal host string (kept the fence-check clean).
- Added an OPTIONAL `city` key to the `JsonAdapter` (hand-editable only, not seeded by `stow.sh`), published as trimmed `cityOverride`; when set it short-circuits the network entirely.
- Mounted `GeocodeBackend { id: geocoder }` as a plain child (not shell-root — single consumer), bound to `drawerOpen`/`lat`/`lon`/`coordsValid`.
- `_resolveCityIfNeeded()` is called from exactly two places (the existing `_revalidateAgainstSettings()` and the `onDrawerOpenChanged` open branch) — no new timer, no new detector.
- The resolved city is cached in `weather-cache.json` (`city` key, OPTIONAL in the load-time shape check so every pre-existing cache still loads) and cleared alongside the payload by the *existing* coordinate-mismatch branch — the single coordinate-change detector, not a second one.
- Published `cityLabel`/`cityLabelSource` (`"override" | "geocoded" | "timezone" | ""`) and a `console.log` on every source transition, since the geocode and the timezone fallback return the identical string for this operator (`Africa/Cairo` → "Cairo") and the log is the only way to tell which path ran.

**Task 3 — `WeatherTab.qml` eyebrow.** Added as the first child of `heroInner`, a `Row` with the `location_city` glyph (`Colours.primary`) and the uppercase city text, reusing the repo's existing small-label triple (`fontLabel`/`weightBody`/`Colours.onSurfaceVariant`) verbatim — no new design tokens. `visible` is gated on `cityLabel !== ""`; a hidden eyebrow costs zero height in the `Column` and needed no edit to the tab's implicit-size formula.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - missing critical functionality] Added `GeocodeBackend.abort()`**
- **Found during:** Task 2(c), writing the coordinate-mismatch invalidation branch.
- **Issue:** The plan's Task 1 spec for `GeocodeBackend.qml` lists no public `abort()` — only the internal `onDrawerOpenChanged` cleanup. But Task 2(c) requires clearing "the child's own last result" on a coordinate mismatch. Without an explicit abort, a request already in flight for the OLD coordinates could resolve after the mismatch branch runs and write a stale city into the NEW coordinates' cache — a real correctness bug, not a style gap.
- **Fix:** Added `GeocodeBackend.abort()` (extracted from the existing `onDrawerOpenChanged` cleanup, now shared) and call it from `WeatherBackend`'s mismatch branch alongside `_cachedCity = ""`.
- **Files modified:** `GeocodeBackend.qml`, `WeatherBackend.qml`.
- **Commits:** `89a6aa1` (initial abort in onDrawerOpenChanged), `ddd61f6` (refactor to shared `abort()` + call site).

**2. [Plan self-contradiction resolved in favour of the mechanical check] `onCityChanged` routing**
- **Found during:** Task 2(b)/(d), writing the override-change handler.
- **Issue:** Plan instruction (b) says `onCityChanged: root._resolveCityIfNeeded()`; instruction (d) says `_resolveCityIfNeeded()` is called from "exactly two places... no third call site," and the Task 2 verify block asserts `grep -c '_resolveCityIfNeeded' == 3` (def + 2 calls) — a third direct call site would make that 4 and fail the plan's own mechanical gate.
- **Fix:** `onCityChanged` calls `root._revalidateAgainstSettings()` (the same chokepoint the other five state-key handlers already use), which itself calls `_resolveCityIfNeeded()` once. Net effect is identical (an override edit re-evaluates the chain immediately) with the call count staying at exactly 3.
- **Files modified:** `WeatherBackend.qml`.
- **Commit:** `ddd61f6`.

**3. [Rule 1 - self-inflicted grep-gate trips, fixed inline before commit] Fence-check and implicit-size-check literal-string collisions**
- **Found during:** running Task 1/2/3's own verify blocks.
- **Issue:** Explanatory prose accidentally tripped the plan's own mechanical checks three times: (a) `GeocodeBackend.qml`'s header named `api.open-meteo.com` literally, breaking the forecast-fence grep (must be exactly 1 file); (b) `WeatherBackend.qml`'s corrected fence paragraph named `nominatim.openstreetmap.org` literally, breaking the geocode-fence grep; (c) `WeatherTab.qml`'s eyebrow comment used the word "implicitHeight" in prose, tripping the "implicit-size block untouched" diff grep.
- **Fix:** Reworded all three to describe the host/property without the literal matched string (e.g. "its own host", "the tab's advisory size formula above") while keeping the same information.
- **Files modified:** `GeocodeBackend.qml`, `WeatherBackend.qml`, `WeatherTab.qml`.
- **Commits:** `89a6aa1`, `ddd61f6`, `05aa069`.

## Gate Results (live, this session)

| Gate | Result |
|------|--------|
| `qmllint` (all 3 touched files) | exit 0, zero errors |
| `colour-lint` | 146 passed, 0 failed |
| `motion-lint` | 293 passed, 0 failed |
| `quickshell-doctor` | 27 passed, 0 failed |
| `theme-doctor` | 585 passed, 1 failed (see note below) |
| `theme-parity` | 1721 passed, 0 failed |
| `stow-link-check` (standalone) | 2 passed, 0 failed |

**theme-doctor's one failure is expected, not a defect:** its `git status --porcelain is empty` check fails only because `.planning/quick/260818-v3m-.../260818-v3m-PLAN.md` (and now this SUMMARY.md) are intentionally left uncommitted per this task's own constraints — the orchestrator commits docs artifacts separately. All 585 other checks, including every quickshell/theme-pipeline check this task could plausibly have broken, pass. Re-running `theme-doctor` after the orchestrator's docs commit should show 586/0.

## Human Verification Required

Per the plan's own instructions, do **not** restart quickshell — QML hot-reloads on file change. Operator should, after this commit:

1. Open the dashboard's weather tab and confirm the eyebrow reads **Cairo** above the temperature.
2. Check which path resolved it via the `onCityLabelSourceChanged` log line — expect `geocoded`, not `timezone` (both produce "Cairo" here, so the log is the only discriminator).
3. Confirm the geocode ran exactly once and was persisted:
   ```bash
   python3 -c "import json;d=json.load(open('$HOME/.local/state/theme/weather-cache.json'));print('city =',repr(d.get('city')))"
   ```
4. Close/reopen the drawer several times and re-check the log — no second `geocoded` transition.

Full plan for troubleshooting steps (User-Agent verification via `curl`, etc.) if step 2 reports `timezone` unexpectedly: see the plan's "Human verification" section.

## Self-Check: PASSED

- `quickshell/.config/quickshell/modules/dashboard/GeocodeBackend.qml` — FOUND
- `quickshell/.config/quickshell/modules/dashboard/qmldir` — FOUND (modified)
- `quickshell/.config/quickshell/modules/dashboard/WeatherBackend.qml` — FOUND (modified)
- `quickshell/.config/quickshell/modules/dashboard/WeatherTab.qml` — FOUND (modified)
- Commit `89a6aa1` — FOUND in `git log --oneline --all`
- Commit `ddd61f6` — FOUND in `git log --oneline --all`
- Commit `05aa069` — FOUND in `git log --oneline --all`
