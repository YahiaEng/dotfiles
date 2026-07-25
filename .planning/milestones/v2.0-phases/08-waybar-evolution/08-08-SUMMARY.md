---
phase: 08-waybar-evolution
plan: 08
subsystem: waybar-eww-integration
tags: [waybar, eww, hyprctl, jq, bash, layer-shell, mpris, security]

requires:
  - phase: 08-waybar-evolution
    provides: "eww installed + pinned CLI surface (08-06); the real, hardened media-popup eww window with its frozen window/arg interface (08-07); the vertical layout + D-17 colour gate (08-05)"

provides:
  - "hypr/.config/hypr/scripts/media-popup-open.sh — cursor-anchored, monitor-clamped `eww open --toggle` wrapper with D-23's ANCHOR_MODE fixed-position fallback as a single constant"
  - "Every waybar layout's media segment (mpris in full/minimal/vertical, custom/media in floating) now opens the eww media popup on click — BAR-04 closes"
  - "Re-baselined D-34 equivalence gate covering all four layouts (vertical included) both before and after the on-click re-point"

affects: []

tech-stack:
  added: []
  patterns:
    - "Anchor-relative eww window coordinates: for a `defwindow` with a fixed `:anchor`, the x/y args passed via `--arg` are offsets from that anchor's corner, not a plain top-left screen position — any script computing a target placement must convert an absolute (top-left-relative) point into that anchor-relative pair immediately before the `eww open` call."
    - "A `fixed`-mode placement pinned to one corner of a monitor is algebraically invariant of the monitor's real width/height once converted to anchor-relative offsets — it degrades cleanly to a hardcoded constant with zero geometry query when hyprctl/jq are unavailable, which is what actually makes it the 'zero new moving parts' fallback RESEARCH.md describes."

key-files:
  created:
    - hypr/.config/hypr/scripts/media-popup-open.sh
  modified:
    - waybar/.config/waybar/modules.jsonc
    - waybar/.config/waybar/config-minimal.jsonc
    - waybar/.config/waybar/config-vertical.jsonc
    - .planning/phases/08-waybar-evolution/.waybar-config-baseline/full.json
    - .planning/phases/08-waybar-evolution/.waybar-config-baseline/minimal.json
    - .planning/phases/08-waybar-evolution/.waybar-config-baseline/vertical.json
    - .planning/phases/08-waybar-evolution/.waybar-config-baseline/floating.json
    - .planning/phases/08-waybar-evolution/deferred-items.md

key-decisions:
  - "ANCHOR_MODE ships as `fixed`, not `cursor`, this session. Every physical DRM display connector was `disconnected` at the kernel level (verified: `/sys/class/drm/*/status`), so Hyprland reported zero monitors and every `eww open` attempt failed with \"Failed to get monitor 0\" — no live on-screen placement, of any kind, was possible. D-23 pre-authorises taking the fixed fallback 'without debate' whenever cursor-anchoring can't be trusted; being unable to verify it AT ALL is at least as strong a trigger as an empirically-observed jitter. Cursor mode is fully implemented and reasoned from confirmed facts (see Coordinate Space below), ready to flip and verify once a monitor is attached."
  - "config-floating.jsonc required ZERO direct edit, contradicting this plan's own `<critical_finding>` table. Resolving (not assuming) config-floating.jsonc showed `custom/media` has no private redefinition there — it is a single shared canonical definition in `modules.jsonc` (already living there per D-31, 'kept shared... so any future layout can list them'), referenced only by floating. Editing `modules.jsonc`'s one `custom/media.on-click` reaches floating by inheritance, exactly like `mpris` reaching `config-full.jsonc`. Creating a redundant private copy in `config-floating.jsonc` would have violated D-31's own shared-definition discipline."
  - "The eww window's `:anchor \"top right\"` (08-07's frozen defwindow value) means the x/y this script hands to `eww open` are NOT a left-top screen offset — they are the distance from the monitor's right/top edges to the window's right/top edges. The script always computes an ordinary absolute placement first, then converts to that anchor-relative pair in `_abs_to_anchor_offset_x/_y`, which stays correct for a monitor at any origin (verified by hand for a synthetic second monitor at x-origin 1920 — see Coordinate Space below)."

patterns-established:
  - "Coordinate-space reasoning from documented facts when live measurement is categorically unavailable: derive the anchor-offset conversion algebraically from eww's own confirmed docs quote ('x/y relative to anchor') and the frozen window definition, verify the arithmetic offline with synthetic hyprctl-shaped JSON and a hand-worked reverse-derivation of the resolved window rectangle, then flag the live-verification gap explicitly rather than asserting an unverified pass."

requirements-completed: [BAR-04]

coverage:
  - id: D1
    description: "media-popup-open.sh: cursor-anchored, monitor-clamped, with D-23's ANCHOR_MODE fixed fallback as a one-constant flip"
    requirement: "BAR-04"
    verification:
      - kind: unit
        ref: "bash -n + shellcheck -S error clean; comment-stripped grep confirms zero eval/sh -c/SIGUSR"
        status: pass
      - kind: integration
        ref: "Offline arithmetic + reverse-derivation of the resolved window rectangle for 5 synthetic placements (far-right-top-bar, bottom-edge, vertical-column-left, bottom-right-corner, second-monitor-non-origin) — all 5 resolve fully on-screen"
        status: pass
      - kind: integration
        ref: "PATH-shimmed hyprctl/eww live-execution tests: cursor mode, degraded fixed mode (no hyprctl/jq), pathological-tiny-monitor clamp, malformed/hostile cursorpos rejection, single-flight flock under concurrent invocation (4ms return while lock held)"
        status: pass
      - kind: manual_procedural
        ref: "ANCHOR_MODE flipped on the actual shipped file (fixed→cursor→fixed) with a hyprctl shim in PATH: fixed produced x=10,y=10; cursor (cursor at 1900,20) produced x=8,y=40; git diff clean after flipping back"
        status: pass
    human_judgment: true
    rationale: "Live on-screen placement against a real monitor (the four-corner cursor matrix, click-away/Esc close, and the human-check visual pass) could not be performed this session — every DRM connector was disconnected, so Hyprland had zero monitors and eww could not open any window at all ('Failed to get monitor 0'). This is a hardware-level environmental blocker, not a code defect; a human must re-verify via Super+B once a monitor is attached, per this phase's own established precedent (08-05's pending grim/screencopy visual pass)."
  - id: D2
    description: "Every layout's media segment (mpris in full/minimal/vertical, custom/media in floating) re-pointed to the popup opener; on-click-right/on-scroll quick actions and format-stopped's D-25 empty state survive untouched"
    requirement: "BAR-04"
    verification:
      - kind: integration
        ref: "waybar-equivalence-check --resolve on all four config-*.jsonc: every media segment's on-click ends in media-popup-open.sh; grep -c play-pause across all configs == 0; on-click-right/on-scroll-up/on-scroll-down/format-stopped all intact"
        status: pass
      - kind: integration
        ref: "waybar-equivalence-check waybar/.config/waybar — reviewed diff showed exactly one key changed per layout (on-click), re-snapshotted, gate green 4 PASS / 0 FAIL / 0 SKIP"
        status: pass
      - kind: manual_procedural
        ref: "Simulated the exact deployed on-click string via /bin/sh -c (as waybar itself would invoke it) against the live symlinked config after a real waybar relaunch (uwsm app -- waybar-launch.sh, floating layout) — exit 0, correctly dispatched to media-popup-open.sh"
        status: pass
    human_judgment: true
    rationale: "A literal mouse click on the real bar segment, and the popup's visual open/close/click-away/Esc behavior, could not be exercised this session (no monitor attached — see D1's rationale). The click path was proven correct up to eww's own window-open call; the remaining step (a physical click producing a visible, correctly-placed popup) needs a human with a monitor."

duration: ~20min
completed: 2026-07-14
status: complete
---

# Phase 8 Plan 08: Media Popup Wiring Summary

**Every waybar layout's media segment now opens the eww media popup on click via a new cursor-anchored, monitor-clamped opener script — closing BAR-04 — but ships with D-23's pre-authorised fixed-position fallback as the active default because every physical display was hardware-disconnected this session, making live on-screen verification of the cursor-anchored math categorically impossible.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-14T16:57:59+03:00 (vertical baseline snapshot)
- **Completed:** 2026-07-14T17:17:00+03:00 (approx)
- **Tasks:** 2/2 (plus the required pre-step baseline commit)
- **Files modified:** 8 (1 created script, 3 config edits, 4 re-snapshotted baselines) + 1 planning doc note

## Accomplishments

- **`media-popup-open.sh` built and hardened.** Reads `hyprctl cursorpos`, selects the containing monitor (falling back to focused, then to a silent no-op), computes an absolute clamped placement, converts it into `media-popup`'s fixed `:anchor "top right"` offset space, and calls `eww open --toggle` in array form. Single-flight `flock` guard, anchored-integer validation on every hyprctl-derived value, zero positional args, zero mpris metadata, no `eval`/`sh -c`/`SIGUSR` anywhere (all grep-verified).
- **Every layout's media segment re-pointed.** `modules.jsonc`'s canonical `mpris` (reaches `config-full.jsonc` by inheritance) and canonical `custom/media` (reaches `config-floating.jsonc` by inheritance — a corrected Step A finding, see Deviations) both got their `on-click` re-pointed; `config-minimal.jsonc` and `config-vertical.jsonc`'s private `mpris` redefinitions got the same. Exactly one key changed per site everywhere — `on-click-right`/`on-scroll-up`/`on-scroll-down` and `format-stopped`'s empty D-25 state are untouched, verified by resolving all four layouts.
- **D-34 equivalence gate re-baselined twice, deliberately.** First, the vertical layout (which had no baseline at all, per this plan's REQUIRED_FIRST_STEP) was snapshotted alone, in its own commit, before any functional edit — gate went from 3 PASS/0 FAIL/1 SKIP to 4 PASS/0 FAIL/0 SKIP. Second, after the on-click re-point, the diff was read and confirmed to contain exactly one key change per layout before re-snapshotting — gate returned to 4 PASS/0 FAIL/0 SKIP.
- **Media hardening gate re-confirmed 19/19** (`tests/test-media-hardening.sh`) after all edits — this plan introduces no new player-metadata surface, and 08-07's hardening holds.
- **Environment-blocked live verification, honestly documented, not faked.** Every DRM connector (`/sys/class/drm/*/status`) reported `disconnected` throughout this session — Hyprland had zero monitors, and every `eww open` attempt failed with `Failed to get monitor 0`. The four-corner cursor matrix, the toggle-close check, and the human-check visual pass could not be run against a real screen. Compensated with: (1) offline arithmetic + hand reverse-derivation of the resolved window rectangle for 5 synthetic placements including the vertical-column-left and a non-origin second-monitor case (all 5 resolve fully on-screen); (2) PATH-shimmed live-execution tests of every code path (cursor mode, degraded fixed mode, pathological-tiny-monitor clamp, hostile/malformed cursorpos rejection, concurrent single-flight); (3) flipping `ANCHOR_MODE` on the real shipped file and observing the placement change, then restoring it with a clean `git diff`; (4) simulating the exact deployed `on-click` string via `/bin/sh -c` against the live, relaunched waybar config.

## Task Commits

1. **Required first step: baseline the vertical layout** — `34e362a` (chore)
2. **Task 1: media-popup-open.sh** — `aea2b3a` (feat)
3. **Task 2: re-point every layout's on-click + re-baseline** — `4238e2d` (feat)

**Plan metadata:** (this commit, following)

## Pinned eww CLI (re-confirmed this session against the installed binary)

| Item | Status | Finding |
|---|---|---|
| `eww open --toggle` | CONFIRMED | Exists exactly as spelled — re-ran `eww open --help`, matches 08-06's pinning verbatim. |
| `--arg <ARGS>`, form `name=value` | CONFIRMED | `eww open --help`'s own text: `--arg "var_name=value"`. Used as `--arg "x=${eww_x}" --arg "y=${eww_y}"`. |
| `--screen <SCREEN>` (monitor selector) | CONFIRMED to exist, NOT USED | `eww open --help`: "The identifier of the monitor the window should open on." Not passed by this script — `media-popup`'s `defwindow` hardcodes `:monitor 0` (08-07's frozen interface, out of this plan's `files_modified`), so on this single-monitor machine `--screen` would be redundant. Whether it accepts a monitor *name* (`DP-1`) or only a numeric index could not be empirically distinguished this session (no monitor to test against) — recorded as an open question for whoever revisits multi-monitor support. |
| `eww close [WINDOWS]...` | CONFIRMED (re-ran `eww close --help`) | Unchanged from 08-06's pinning; not directly invoked here (`--toggle` on `eww open` handles both directions per the frozen interface). |
| `eww open` auto-spawns the daemon | CONFIRMED again | Cold `eww open` still prints the daemon-init banner before attempting the window. |

## Coordinate Space Finding (Step B — required record)

**Live `hyprctl layers -j` measurement against a real eww window was impossible this session** (see Deviations/Known limitation below) — `eww open` itself fails before ever creating a surface, because `defwindow`'s hardcoded `:monitor 0` cannot resolve when Hyprland reports zero monitors. This is a strictly earlier failure point than the coordinate-space question the plan's Step B asks about, so it could not be answered by direct measurement this session.

**Resolved instead by documented fact + arithmetic, not guesswork:** `08-RESEARCH.md`'s VERDICT 2 quotes eww's own configuration docs verbatim: *"x and y values will be relative to anchor."* `media-popup`'s shipped `defwindow` (08-07, `eww/.config/eww/eww.yuck`) declares a **fixed, static** `:anchor "top right"`. Combined, this means the `x` this script hands to `eww open` is the distance from the **monitor's right edge** to the window's right edge, and `y` is the distance from the monitor's **top edge** to the window's top edge — not a plain left-top screen offset, and there is a real, load-bearing difference: passing a raw absolute left-top coordinate straight through would misplace the popup by roughly `(monitor_width - 2*x - POPUP_W)` pixels on any monitor wider than the popup.

The script therefore always computes an ordinary absolute (top-left-relative) target rectangle first — exactly like every other coordinate in this repo — then converts via `_abs_to_anchor_offset_x/_y` (`eww_x = mon_x + mon_w - abs_x - POPUP_W`; `eww_y = abs_y - mon_y`) immediately before the `eww open` call. Both conversions subtract only quantities derived from the *same* resolved monitor rectangle, so the math is correct for a monitor at any origin, not just `(0,0)` — verified by hand for a synthetic second monitor at x-origin 1920 (`hyprctl monitors -j`-shaped test fixture; see the offline arithmetic table below). **A future second monitor will not silently break this**, because the origin subtraction is generic, not hardcoded to zero.

Offline verification table (reverse-derived resolved window rect from the computed `eww_x`/`eww_y`, confirming full on-screen containment):

| Scenario | cursor/target | monitor rect | `eww` offset | resolved rect | on-screen? |
|---|---|---|---|---|---|
| far-right, top bar | (1900,20) | [0,0..1920,1080] | (8,40) | [1612,40..1912,600] | yes |
| bottom edge | (960,1070) | [0,0..1920,1080] | (810,512) | [810,512..1110,1072] | yes |
| vertical column, left edge | (24,500) | [0,0..1920,1080] | (1612,512) | [8,512..308,1072] | yes |
| bottom-right corner | (1900,1070) | [0,0..1920,1080] | (8,512) | [1612,512..1912,1072] | yes |
| second monitor, non-origin | (2500,300) | [1920,0..3456,864] | (806,296) | [2350,296..2650,856] | yes |

The `fixed`-mode offset is additionally provable to be **invariant of the real monitor rectangle once converted** — algebraically, `eww_x` for the fixed placement always reduces to exactly `FIXED_OFFSET` (10) regardless of `mon_x`/`mon_w`'s actual values, which is what makes it genuinely the "zero new moving parts" fallback RESEARCH.md describes, and why the degraded (no-hyprctl/no-jq) path can emit `x=10,y=10` directly with no monitor query at all.

## D-23 Verdict: ANCHOR_MODE ships as `fixed`

**Shipped:** `ANCHOR_MODE="fixed"`.

**Measured placement error:** none measurable — not "zero error," but literally **no measurement was possible**, because every physical DRM display connector (`card1-DP-1`, `-DP-2`, `-HDMI-A-1`, `-HDMI-A-2`) reported `disconnected` at `/sys/class/drm/*/status` for the entire session, `hyprctl monitors -j`/`monitors all -j` both returned `[]`, and every `eww open` attempt (including ones from before this script existed) failed with `Failed to get monitor 0. The available monitors are:` (empty). `hyprctl dispatch dpms on` had no effect — this is a hardware-level disconnection, not a software sleep state this executor can reverse.

**Why `fixed`, not `cursor`:** D-23 pre-authorises taking the fixed-position fallback "without debate" whenever cursor-anchoring can't be trusted. Being unable to verify it *at all* — not even once, on any layout — is at least as strong a trigger for that clause as an empirically observed jitter would have been. Shipping the cursor-anchored math as the *default* with zero live confirmation would risk an off-screen popup with no way to detect it until a real user complained; shipping the algebraically-provable, monitor-geometry-invariant fixed fallback as the default carries none of that risk.

**Cursor mode is fully implemented, not stubbed.** It is reasoned from the same confirmed anchor-offset facts above, offline-arithmetic-verified across 5 synthetic placements (including the vertical-column-left case explicitly named in this plan's must_haves), and PATH-shim-tested end-to-end (see Verification below). Flip `ANCHOR_MODE` to `cursor` in `hypr/.config/hypr/scripts/media-popup-open.sh` and re-verify with Super+B once a monitor is attached — that single edit is the whole change required, exactly as the plan's own acceptance criterion demands.

## Layout Map — What Actually Needed an Edit (Step A, resolved not assumed)

| Layout | Media segment | Redefines it? | Edited? |
|---|---|---|---|
| `config-full.jsonc` | `mpris` | no — inherits canonical | **no** — inherits the `modules.jsonc` edit for free |
| `config-minimal.jsonc` | `mpris` | yes, full redefinition | **yes** — own `on-click` re-pointed |
| `config-vertical.jsonc` | `mpris` | yes, full redefinition (confirmed by `--resolve`, not assumed) | **yes** — own `on-click` re-pointed |
| `config-floating.jsonc` | `custom/media` | **no** — corrected finding, see below | **no** — inherits the `modules.jsonc` edit for free |

**Corrected finding (supersedes this plan's own `<critical_finding>` table):** the plan assumed `config-floating.jsonc` carries a *private* full definition of `custom/media` needing its own edit ("its own click binding at line 53"). Resolving the live file showed this is stale — `custom/media` is defined **once**, in `modules.jsonc` (already shared there per D-31: "kept shared... so any future layout can list them without a copy-paste"), and `config-floating.jsonc` only *references* it by name in `modules-left`. `grep -rn '"custom/media"' waybar/.config/waybar/*.jsonc` shows exactly two hits: the one reference in floating, and the one definition in `modules.jsonc`. Editing the shared definition's `on-click` therefore reaches floating automatically, the same way editing `mpris` reaches `config-full.jsonc`. Creating a redundant private copy in `config-floating.jsonc` would have violated D-31's own shared-definition discipline for no reason. `git status --short` after this plan's edits confirms `config-floating.jsonc` and `config-full.jsonc` show **zero diff** — proof the inheritance path, not a direct edit, is what carries the fix to both.

## Reviewed Equivalence Diff (verbatim, before re-snapshot)

```
[FAIL] floating: differs from baseline
-  "on-click": "playerctl play-pause",
+  "on-click": "~/.config/hypr/scripts/media-popup-open.sh",
   (custom/media, all other keys unchanged)

[FAIL] full: differs from baseline
-  "on-click": "playerctl play-pause",
+  "on-click": "~/.config/hypr/scripts/media-popup-open.sh",
   (mpris, all other keys unchanged)

[FAIL] minimal: differs from baseline
-  "on-click": "playerctl play-pause",
+  "on-click": "~/.config/hypr/scripts/media-popup-open.sh",
   (mpris, all other keys unchanged)

[FAIL] vertical: differs from baseline
-  "on-click": "playerctl play-pause",
+  "on-click": "~/.config/hypr/scripts/media-popup-open.sh",
   (mpris, all other keys unchanged)

PASS: 0  FAIL: 4
```

Confirmed this contained **exactly one key** per layout — `on-click` on the media-segment module — and nothing else, in exactly the four layouts expected. Re-snapshotted; gate returned to `PASS: 4  FAIL: 0`.

## Files Created/Modified

- `hypr/.config/hypr/scripts/media-popup-open.sh` — new; cursor-anchored/monitor-clamped/anchor-converting `eww open --toggle` wrapper, `ANCHOR_MODE="fixed"` shipped
- `waybar/.config/waybar/modules.jsonc` — `mpris.on-click` and `custom/media.on-click` both re-pointed (two shared definitions, one file)
- `waybar/.config/waybar/config-minimal.jsonc` — `mpris.on-click` re-pointed (private redefinition)
- `waybar/.config/waybar/config-vertical.jsonc` — `mpris.on-click` re-pointed (private redefinition)
- `.planning/phases/08-waybar-evolution/.waybar-config-baseline/{full,minimal,vertical,floating}.json` — re-snapshotted twice: once to add the missing vertical baseline (pre-step), once after the reviewed on-click diff
- `.planning/phases/08-waybar-evolution/deferred-items.md` — appended a note reconciling 08-07's "delete media-player.py" suggestion with this plan's actual (and binding) "touch only on-click" scope

## Decisions Made

- `ANCHOR_MODE` ships `fixed` — see "D-23 Verdict" above.
- `config-floating.jsonc` gets no direct edit — see "Layout Map" above.
- The anchor-relative coordinate conversion is derived from documented facts + arithmetic, not re-guessed — see "Coordinate Space Finding" above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Own comment tripped the `grep -c 'SIGUSR'` acceptance check**
- **Found during:** Task 1, running the literal acceptance-criteria grep against the just-written script.
- **Issue:** A header comment literally spelled out "SIGUSR1/SIGUSR2" while explaining why the script never sends them — tripping the exact-string check even though no signal is ever sent. Identical false-positive class to 08-05's deviation #5.
- **Fix:** Reworded to "a hide/reload signal" without the literal token.
- **Files modified:** `hypr/.config/hypr/scripts/media-popup-open.sh`
- **Verification:** `grep -c 'SIGUSR' media-popup-open.sh` returns 0; the no-signal guarantee is unchanged.
- **Committed in:** `aea2b3a` (Task 1 commit — fixed before committing, not a separate commit).

### Corrected Plan Assumptions (not bugs — Step A's own "do not trust this plan's table" instruction)

**2. `config-floating.jsonc` needed zero direct edit**, contradicting the plan's `<critical_finding>` table (see "Layout Map" above for the full reasoning). No file was edited that the plan's files_modified list named but turned out unnecessary to touch — `config-floating.jsonc` is listed in `files_modified` but ends up with a clean `git diff` because the fix reaches it by inheritance.

### Environment Limitation (not a deviation — hardware, not a bug)

**3. Live on-screen verification could not be performed.** Every DRM connector was disconnected for the entire session; `hyprctl monitors -j`/`monitors all -j` returned `[]`; every `eww open` attempt failed with `Failed to get monitor 0`. Compensating evidence gathered instead: offline arithmetic + reverse-derivation across 5 synthetic placements, PATH-shimmed live-execution tests of every branch (cursor/fixed/degraded/pathological-clamp/hostile-input-rejection/single-flight), and an on-the-real-file `ANCHOR_MODE` flip-and-restore. See coverage item D1/D2's `rationale` for the exact reproduction steps. A stray, wedged `eww` daemon left over from an earlier manual coordinate-space probe (before this limitation was fully understood) was found and killed during this session's own verification — not left running.

### Deferred Items (pre-existing, out of scope, not fixed)

- **`theme-doctor`'s git-clean check** still fails on the same three pre-existing dirty paths (`wallpapers/Pictures/Wallpapers/current.jpg`, `.planning/phases/07-super-key-menu/07-VERIFICATION.md`, `csv`) logged since 08-06 — untouched by this plan.
- **`./stow.sh` still aborts early on the pre-existing vscodium `settings.json` conflict** (logged since 08-01/08-03) — did not block this plan, since `waybar`, `hypr`, and `eww` were already correctly symlinked from earlier sessions (confirmed via matching inode numbers between the repo path and the deployed `~/.config/...` path for both `media-popup-open.sh` and the edited waybar configs); relaunched waybar directly via `uwsm app -- waybar-launch.sh` instead of relying on a full `./stow.sh` pass.
- **08-07's suggestion to delete `media-player.py`/`custom/media`** was deliberately NOT followed — see the reconciliation note appended to `deferred-items.md`, and "Layout Map" above.

---

**Total deviations:** 1 auto-fixed (Rule 1, comment wording), 1 corrected plan assumption (not a bug), 1 environment limitation (hardware, honestly documented rather than faked).
**Impact on plan:** BAR-04 is code-complete and provably wired end-to-end up to the point a real display is required — the remaining gap is a human visual pass with a monitor attached, not unfinished work.

## Known Stubs

None. `media-popup-open.sh` is a complete, hardened implementation of both its modes — `fixed` is the active default, `cursor` is fully implemented and one constant away, not a placeholder.

## User Setup Required

**A monitor must be attached** (or the currently-disconnected DRM connector reconnected) before the popup can be visually verified. Once it is:
1. Optionally flip `ANCHOR_MODE` in `hypr/.config/hypr/scripts/media-popup-open.sh` from `fixed` to `cursor` to try the primary D-23 behavior.
2. Run the human-check from `08-08-PLAN.md`: with a player running, cycle Super+B through all four layouts, click the media segment in each, confirm the popup opens on-screen, closes on re-click/click-away/Esc, and that right-click/scroll still work without opening it.
3. Flip back to `fixed` (or leave on `cursor`) based on what's observed — either way, update this plan's `ANCHOR_MODE` note if the shipped default changes.

## Next Phase Readiness

- **BAR-04 closes** — the eww media popup is wired to waybar's media segment in all four layouts. No further plans in this phase depend on this one (`affects: []` in frontmatter).
- **Outstanding:** the human visual pass described above is the one remaining verification step for this plan, blocked purely on hardware (no monitor attached this session) — not a code gap.

---
*Phase: 08-waybar-evolution*
*Completed: 2026-07-14*

## Self-Check: PASSED

- `test -x hypr/.config/hypr/scripts/media-popup-open.sh` -> FOUND, executable
- `test -f waybar/.config/waybar/.waybar-config-baseline` n/a (directory, see below)
- `test -f .planning/phases/08-waybar-evolution/.waybar-config-baseline/vertical.json` -> FOUND
- `git log --oneline --all | grep 34e362a` -> FOUND
- `git log --oneline --all | grep aea2b3a` -> FOUND
- `git log --oneline --all | grep 4238e2d` -> FOUND
- `hypr/.config/hypr/scripts/waybar-equivalence-check waybar/.config/waybar/` -> PASS: 4 FAIL: 0 (re-run at self-check time)
- `hypr/.config/hypr/scripts/tests/test-media-hardening.sh` -> 19 passed, 0 failed (re-run at self-check time)
