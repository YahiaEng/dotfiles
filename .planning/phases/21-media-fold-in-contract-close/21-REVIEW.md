---
phase: 21-media-fold-in-contract-close
reviewed: 2026-08-16T20:20:00Z
depth: standard
files_reviewed: 34
files_reviewed_list:
  - cava/.config/cava/config
  - .gitignore
  - hypr/.config/hypr/config/autostart.lua
  - hypr/.config/hypr/config/keybinds.lua
  - hypr/.config/hypr/config/windowrules.lua
  - hypr/.config/hypr/scripts/motion-lint
  - hypr/.config/hypr/scripts/quickshell-doctor
  - hypr/.config/hypr/scripts/retirement-check
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-no-mpris-reader.qml
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/MediaBackend.qml
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-prose-only-mpris-mention.qml
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-second-mpris-reader.qml
  - hypr/.config/hypr/scripts/tests/test-media-hardening.sh
  - install.sh
  - matugen/.config/matugen/config.toml
  - quickshell/.config/quickshell/modules/bar/BarRoles.qml
  - quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml
  - quickshell/.config/quickshell/modules/bar/MediaPopout.qml
  - quickshell/.config/quickshell/modules/CavaService.qml
  - quickshell/.config/quickshell/modules/dashboard/Design.qml
  - quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml
  - quickshell/.config/quickshell/modules/dashboard/MediaTab.qml
  - quickshell/.config/quickshell/modules/Dashboard.qml
  - quickshell/.config/quickshell/modules/Overview.qml
  - quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml
  - quickshell/.config/quickshell/modules/qmldir
  - quickshell/.config/quickshell/shell.qml
  - quickshell/.config/quickshell/shortcuts.json
  - quickshell/.config/systemd/user/quickshell.service
  - stow.sh
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/contract.sh
  - theme-engine/.config/theme-engine/lib/reload.sh
  - theme-engine/.config/theme-engine/theme-parity
findings:
  critical: 1
  warning: 3
  info: 1
  total: 5
status: issues_found
---

# Phase 21: Code Review Report

**Reviewed:** 2026-08-16T20:20:00Z
**Depth:** standard
**Files Reviewed:** 34
**Status:** issues_found

## Summary

Reviewed the media fold-in / AGS retirement work: `CavaService.qml` (new
ref-counted cava singleton), the MPRIS dedup/seek-latch/per-player-volume
additions in `MediaBackend.qml`, the 60-bar radial visualiser shipped
identically into both `MediaTab.qml` (dashboard) and `MediaPopout.qml`
(bar), the DND bell in `ClockActionsCapsule.qml`, and the retirement
sweep across `quickshell-doctor`, `retirement-check`, `motion-lint`,
`install.sh`, `stow.sh`, `matugen/config.toml` and the `theme-engine`
lib. The retirement sweep itself is clean — no dangling `ags`
references, no orphaned contract/template entries, stow package list
correctly swapped, `quickshell-doctor`'s promoted MPRIS-reader-count
check and its four new fixtures are internally consistent, and no
hardcoded colours or `set -o pipefail` + `grep -q` foot-guns were
introduced in the new script code.

The one real functional defect is a genuine regression: the visualiser
ring in the bar's `MediaPopout.qml` is missing the "active player is
actually playing" gate that `MediaTab.qml` explicitly added earlier in
this same phase to fix an operator-reported defect ("browser playing,
switch to a paused Spotify, ring still dancing"). The exact same
condition reproduces in the popout, which was ported from the tab but
dropped that one guard. Three further data-validation/consistency
warnings are recorded below, plus one code-duplication note.

## Critical Issues

### CR-01: MediaPopout's visualiser ring animates on a paused player (missing `playing` gate)

**File:** `quickshell/.config/quickshell/modules/bar/MediaPopout.qml:211-215`
**Issue:**
`MediaTab.qml` explicitly gates its visualiser bars on the *active
player's own play state*, not just on cava streaming, and documents why
at length (`quickshell/.config/quickshell/modules/dashboard/MediaTab.qml:791-817`):

> `root.backendPlaying` is load-bearing, not belt-and-braces. Cava
> monitors the SYSTEM AUDIO OUTPUT, not the selected MPRIS player — so
> with a browser still playing, cava keeps streaming no matter which
> player the switcher has selected. Gating on `CavaService.streaming`
> alone therefore drew a live ring around a PAUSED source's cover art
> whenever anything else on the system was making noise
> (operator-reported at Plan 08's gate: browser playing, switch to a
> paused Spotify, ring still dancing).

`MediaTab.qml`'s bar delegate correctly implements the fix:

```qml
readonly property bool hasLiveData: root.backendPlaying
    && CavaService.streaming
    && CavaService.bars.length > visualiserBar.barIndex
```

`MediaPopout.qml`'s otherwise-identical bar delegate (ported from the
same design, same file header naming it as "identical construction to
MediaTab.qml's") omits the `playing` term entirely:

```qml
readonly property bool hasLiveData: CavaService.streaming
    && CavaService.bars.length > popoutVisualiserBar.barIndex
```

`root.mediaBackend.playing` is referenced exactly once in this file (for
the play/pause glyph at line 473) and never consulted by the ring. The
result: hovering the bar's media capsule for a **paused** player, while
any other audio is playing anywhere on the system (a browser tab, a
second app, etc.), shows the popout's visualiser ring dancing around
album art for a track that is not playing — the identical defect
already found and fixed in the sibling surface within this same phase.

**Fix:**
```qml
readonly property bool hasLiveData: (root.mediaBackend && root.mediaBackend.playing === true)
    && CavaService.streaming
    && CavaService.bars.length > popoutVisualiserBar.barIndex
```

## Warnings

### WR-01: CavaService does not validate parsed bar values before publishing

**File:** `quickshell/.config/quickshell/modules/CavaService.qml:114-130`
**Issue:** The file's own header and inline comments describe this
parser as defending against "a malformed or hostile stdout line" (line
47-48), but `onRead` only filters on string length, not numeric
validity:

```qml
const vals = line
    .split(";")
    .filter(s => s.length > 0)
    .map(s => Number(s) / 100)
    .slice(0, root.barCount);
if (vals.length > 0)
    root._bars = vals;
```

A non-numeric token (e.g. a torn/binary-corrupted line, or any
non-decimal text) produces `NaN` via `Number(s)`, and `vals.length > 0`
only checks the *count* survives, not that every value is finite — so a
single bad token still gets published into `root._bars`. Every
downstream consumer clamps with `Math.max(0, Math.min(1, ...))`, and
`Math.min`/`Math.max` both propagate `NaN` (they do not treat it as
"less than everything"), so the affected bar's `shapedAmplitude` and
`outerRadius` (`Math.pow(NaN, 0.45)` etc., in both `MediaTab.qml` and
`MediaPopout.qml`) become `NaN`, producing a broken/invisible path
segment for that bar until the next well-formed frame arrives.

**Fix:**
```qml
const vals = line
    .split(";")
    .map(s => Number(s) / 100)
    .filter(n => Number.isFinite(n))
    .slice(0, root.barCount);
```

### WR-02: `bars` briefly re-exposes stale amplitude data on re-claim after a linger kill

**File:** `quickshell/.config/quickshell/modules/CavaService.qml:52-58, 106-131`
**Issue:** `bars` is defined as `cavaProcess.running ? root._bars : []` —
correct for hiding stale data while the process is stopped. But
`root._bars` itself is never reset when `running` transitions to
`false` (there is no `onRunningChanged` handler, and `release()`/the
linger `Timer` only ever flip `cavaProcess.running`). `claim()` sets
`cavaProcess.running = true` synchronously, before the freshly-started
process has emitted its first line, so for the window between a re-claim
and the first new `stdout` line (the file's own comment measures cold
start at "~350ms"), `bars` returns whatever `_bars` held from *before*
the previous kill — i.e. amplitude data from an earlier, possibly
unrelated, session/track. This directly contradicts the design's own
stated invariant ("Silence AND failure both render the SAME silhouette",
`quickshell/.config/quickshell/modules/dashboard/MediaTab.qml:741-747`):
the silence silhouette is skipped for that window in favour of a stale
one.

**Fix:**
```qml
function claim() {
    root._claimCount += 1;
    lingerTimer.stop();
    if (!cavaProcess.running) {
        root._bars = [];
        cavaProcess.running = true;
    }
}
```

### WR-03: Player dedup only compares a new entry against each group's first member, not the whole cluster

**File:** `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml:170-189`
**Issue:** `_playerGroups` places a player `p` into an existing group only
if `_isSamePerceptualSource(groups[g][0], p)` — i.e. it compares `p`
against the group's first (anchor) member only, never against the other
members already placed in that group:

```qml
for (var g = 0; g < groups.length; g++) {
    if (root._isSamePerceptualSource(groups[g][0], p)) {
        groups[g].push(p);
        placed = true;
        break;
    }
}
```

For three or more genuinely-duplicate perceptual sources (A, B, C) where
A~B and B~C both hold under `_isSamePerceptualSource` but A~C does not
(realistic given the position/length proximity test has independent
2-second windows per comparison), the group is order-dependent: if C is
evaluated against A first and fails, C starts its own group even though
it is a real duplicate of B, which is already in A's group. The file's
own comment states "all four readers agree on exactly the same collapse"
as the reason this logic is centralized — that guarantee holds for
pairwise duplicates but not for 3+-way clusters.

**Fix:** Compare against every existing member of the candidate group
(or re-run a transitive-closure pass) rather than only `groups[g][0]`:
```qml
for (var g = 0; g < groups.length; g++) {
    var matchesGroup = false;
    for (var m = 0; m < groups[g].length; m++) {
        if (root._isSamePerceptualSource(groups[g][m], p)) { matchesGroup = true; break; }
    }
    if (matchesGroup) { groups[g].push(p); placed = true; break; }
}
```

## Info

### IN-01: `_cookiePath()` is ~35 lines of dead code duplicated verbatim in two files

**File:** `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml:551-588`,
`quickshell/.config/quickshell/modules/bar/MediaPopout.qml:80-110`
**Issue:** Both files carry an identical, unreachable 12-lobe SVG
cookie-path generator, kept (per the header comments) so the shape
"can be restored by swapping one `PathSvg` call" after the operator
reversed D-21-02 back to a plain circle. This is a deliberate choice,
documented as such, but it doubles the dead-code/maintenance surface for
a feature that has already been rejected once — any future geometry
tweak to the live circle mask has no corresponding update path for this
duplicate, and a future reader has to independently verify both copies
stayed in sync if the cookie shape is ever revisited.
**Fix:** If reversibility is still wanted, consider parking the cookie
generator in one shared file (or the phase's own SUMMARY/PLAN artifact
as a snippet) rather than two live, compiled copies; otherwise delete it
and let the (already-preserved) git history at the D-21-02 commit be the
restoration path.

---

_Reviewed: 2026-08-16T20:20:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
