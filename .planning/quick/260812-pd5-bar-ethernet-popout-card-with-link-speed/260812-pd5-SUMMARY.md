---
status: complete
quick_id: 260812-pd5
date: 2026-08-12
description: "Bar: ethernet popout card with link speed, Update-system tooltip, GPU resource glyph"
commit: 84dbec1, 7204d17, f452eee, 2f896f8, 5752648
files_modified:
  - quickshell/.config/quickshell/modules/bar/EthernetPopout.qml
  - quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml
  - quickshell/.config/quickshell/modules/bar/PopoutController.qml
  - quickshell/.config/quickshell/modules/bar/SystemCapsule.qml
  - quickshell/.config/quickshell/modules/bar/BarEntryModel.qml
  - quickshell/.config/quickshell/modules/bar/qmldir
  - hypr/.config/hypr/scripts/quickshell-doctor
---

# Quick Task 260812-pd5 — four operator items on the bar

Raised during GATE-02's iteration-2 sitting. One needed no code at all; the other three
landed in two commits.

## 1. Ethernet glyph had no popout card — FIXED (`7204d17`)

Confirmed: it shipped as a bare `Readout`, the only glyph in that capsule whose click did
nothing, immediately beside a network glyph that opened a full card.

**Contents were bounded by measurement, not by the mockup.** A temporary `ETHPROBE` (removed
before commit) enumerated what `Networking.devices`' Wired entry actually publishes:

| Field | Value | Used? |
|---|---|---|
| `name` | `eno1` | ✓ interface |
| `linkSpeed` | `1000` (number) | ✓ Mb/s — matches `/sys/class/net/eno1/speed` exactly |
| `hasLink` | `true` | ✓ |
| `connected` / `state` | `true` / `2` | ✓ |
| `address` | `74:56:3C:5D:91:B2` | ✓ — this is the **MAC**, labelled as such |
| `network.name` | `eno1` | mirrors the device name, NOT the NM profile |
| `interface`, `ip4`, `ipv4`, `addresses`, `activeConnection` | **undefined** | do not exist |

The first proposal promised the connection name ("Fiber") and `192.168.0.160/24`. **Neither is
reachable** — there is no IPv4 field on the device and `network.name` is not the profile name.
Both would need an `nmcli` spawn, which `MediaConnectivityCapsule.qml`'s own header forbids
outright ("adds NO new service connection … nothing here polls and nothing spawns"), so they
were dropped rather than smuggled in. Probing rather than guessing was deliberate: this exact
device object already burned one author, whose `managed` predicate would have been falsy
forever because only `nmManaged` exists.

`linkSpeed` being native was the one pleasant surprise — the approved option assumed a
`/sys/class/net` read, and none is needed. The card spawns nothing and polls nothing.

**Four wiring seams**, each recorded rather than assumed:

- `EthernetPopout.qml` — root `SectionPopout`, `sectionId: "ethernet"`, header glyph `"lan"`
- `qmldir` registration
- `PopoutController`'s D-18-16 allowlist **extended from six names to seven**. This is a
  deny-by-default gate whose whole value is that widening it is a visible act, so it is
  recorded as an extension. Verified before editing that nothing asserts the count — the old
  "six-section" wording was prose in two comments, never a machine check.
- `QSD_BAR_COLOUR_ROLE_EXEMPT` gains `EthernetPopout.qml`, keeping all seven popout-content
  files on one colour layer. Without this the new file would have failed D-20's colour-role
  check for using `Colours.*` the way its six siblings do.

GATE-03's `bar-surface-registry` needed **no** new row: its `SectionPopout` entry stores the
pattern prefix `quickshell-bar-`, which `quickshell-bar-ethernet` already matches.

The capsule now resolves the **device** rather than a boolean, with `ethernetConnected` derived
from it, so glyph visibility and card contents cannot disagree about which device they mean.

**One deliberate divergence from the approved preview:** the foot link declares itself
unavailable with a reason instead of reading "Open in dashboard →". Every sibling popout routes
its foot to a real dashboard panel and there is no wired-network panel, so this uses
`SectionPopout`'s designed dimmed-with-reason path rather than shipping a dead link.

## 2. Updates glyph tooltip — FIXED (`84dbec1`)

"Update system", naming the action the click performs. The glyph had no tooltip because the
whole capsule had none — zero `BarTooltipHost` uses against seven other bar files that use it.

**cpu/ram/disk deliberately did NOT get one.** They sit inside `resourcesPopoutTrigger` and
already answer a hover with a full `ResourcesPopout`, so a tooltip there would fight the popout
for the same gesture. The code states why updates is different: it "stays a SIBLING outside
this trigger, deliberately: it already owns a click that starts a package upgrade." That makes
it the one glyph in the capsule with an invisible action and no popout — the same shape GATE-02
finding F3 recorded against the idle bulb.

Implemented as a `HoverHandler`, **not** `hoverEnabled` on the shared `MouseArea`, and disabled
outright on any instance with empty tooltip text. That gating is load-bearing: a hover-accepting
MouseArea on cpu/ram/disk could swallow the hover their popout's dwell path depends on (QBAR-09).

## 3. Do the resource glyphs change colour dynamically? — YES, no work needed

`SystemCapsule.qml`'s `severityColour` already does this, with strict precedence: `errored` →
`BarRoles.danger`, then `metricFraction >= dangerThreshold` → danger, then `>= warnThreshold` →
`BarRoles.warn`, else the ordinary content colour. It tints both the glyph and the value text,
and both boundaries are inclusive by design.

| Metric | warn | danger |
|---|---|---|
| CPU | 0.75 | 0.90 |
| RAM | 0.75 | 0.85 |
| Disk | 0.80 | 0.90 |
| GPU (new) | 0.75 | 0.90 |

Thresholds are lifted from athena's own `config-athena.jsonc` states blocks. Nothing had crossed
75% while the operator was looking, which is why it had never been seen firing.

## 4. GPU in system resources — ADDED (`84dbec1`), and it costs nothing new

`SystemResources.qml` has carried `gpuFraction`/`gpuAvailable`/`gpuState`/`gpuName` since 14-10
Task 2 (DASH-09), sampled from `nvidia-smi` every 4s behind a one-shot presence probe.
`shell.qml` binds that instance's `drawerOpen` to
`dashboardLoader.active || barInstance.requiresResources`, and cpu/ram/disk hold
`requiresResources` true permanently via their `backends: ["resources"]` declarations.

So the sampler has been running all along with nothing on screen reading it. This entry starts
displaying a figure already being paid for — it adds a glyph and no sampling cost.

Measured live before adding it, via a temporary `GPUPROBE` (removed): `drawerOpen=true`
`gpuAvailable=true` `gpuState=populated` `gpuName="NVIDIA GeForce RTX 3070"` `gpuFraction=0.36`.

GPU thresholds follow the CPU entry's pair rather than inventing a third pattern; athena had no
GPU block to lift, having never had a GPU entry. Gated on `gpuAvailable`, so a machine without
an NVIDIA GPU renders today's bar exactly — the same conditional-entry idiom the battery and
ethernet entries use.

`ResourcesPopout.qml` still shows no GPU row, deliberately: its own comment assigns GPU,
network-rate and temperature to the Performance tab. The bar showing GPU while that popout does
not is intentional, and is noted in-source so nobody "fixes" the asymmetry.

## A measurement mistake worth recording

Before the `GPUPROBE`, the GPU sampler was investigated by polling for `nvidia-smi` processes:
400 samples at 50ms over 20s caught **zero**, and a deliberate control spawn *was* caught by the
same method — which was read as proof the sampler was not running. **That conclusion was wrong.**
The direct state read showed `gpuState=populated`, `gpuFraction=0.36`, so it was sampling the
whole time. `nvidia-smi` lives ~20ms and the control was caught only 1 sample in 20, so the
instrument was far too coarse to prove an absence. A `df` sampling run was reported as
inconclusive for the same reason, correctly — the nvidia-smi one should have been too.

Lesson: process-presence polling can support "it IS running", never "it is NOT running". Read
the consumer's own state instead.

## Glyph verification

Both new ligatures — `"lan"` (card header) and `"developer_board"` (GPU entry) — were verified
PRESENT in the installed `MaterialSymbolsRounded` variable font via fontTools, in a check that
included a deliberately nonexistent control name that correctly reported absent. GATE-02 row
A.3's named failure mode is a nonexistent ligature rendering as its own name in plain text.

## Gates

- `colour-lint` — **112 passed, 0 failed** (up from 110; the new file's two checks both pass).
- `quickshell-doctor` — 25 passed, 3 failed. All four bar-relevant checks pass:
  `bar-surface-registry` (rows=5, missing=0, unregistered=0), `bar-colour-role-routing`
  (scanned=16, bad=0), `bar-colour-alpha-resolution` (offenders=none), and
  `bar-reserved-zone-stability` (delta=48, hot-reload identical). The remaining 3 failures are
  in unrelated subsystems (MPRIS writers, swayosd key ownership, Hyprland permission-grant
  paths) and none reference bar geometry, popouts or the system capsule.
- No QML binding errors in `~/.cache/quickshell.log` after any edit.
- Hot-reloaded throughout; quickshell pid `1520318` never restarted.

## Not verified

Nothing here was confirmed by eye — no popout was opened and no glyph was looked at. The
mechanical wiring is checked (gates pass, no binding errors, ligatures verified, device fields
measured), but that the ethernet card renders correctly, that the GPU glyph appears in the right
place, and that the tooltip reads well are all operator observations still outstanding.

## Follow-up round — operator refinements after seeing it live (`f452eee`)

- **GPU glyph** `developer_board` → `view_in_ar`. The board glyph read as generic circuitry and
  sat too close to the CPU entry's chip glyph two slots away.
- **Tooltip casing** → "Update System".
- **Updates state**: no change. It stays hidden at zero pending updates — operator's call, the
  absence is the signal. (`checkupdates` returns 0 on this host, which is why the entry was
  invisible when the question was raised.)
- **Popout foot** → a centred, glyph-only `more_horiz` pill, replacing the left-aligned text pill
  in all seven cards. `popoutFoot` gained a right anchor, since a `horizontalCenter` has nothing
  to centre within until the item spans the frame's inner width, and the pill is now sized off
  the glyph rather than off label width so every card shows an identically sized control. The
  destination text moved into the hover tooltip — and that tooltip now uses the label verbatim
  instead of `"Open " + label.toLowerCase()`, which rendered "Open open wi-fi settings" for all
  seven labels. Harmless while the label was also drawn on the pill; not harmless once the
  tooltip is the only place the destination appears.

## Two quickshell-doctor gate bugs found on the way (`2f896f8`)

The foot change made `bar-surface-registry` report `missing=1` against a registry that was
entirely correct. Chasing that surfaced two separate defects in the gate itself.

**Bug 1 — `producer | grep -q` under `set -uo pipefail`.** `grep -q` exits the instant it
matches, the producer takes SIGPIPE and exits 141, and pipefail reports the pipeline as failed
even though the pattern *was* found. Whether it happens depends on how much output follows the
match — on **file length** — so a check silently changes verdict as a file grows. Measured on the
same file with the namespace present and unchanged in both:

| SectionPopout.qml | pipeline rc |
|---|---|
| 454 lines / 23239 bytes | 0 |
| 484 lines / 25242 bytes | **141** |

A 30-line comment addition was the entire cause of the reported failure.

The failure *direction* differs by site, and one is dangerous:

- Registry closures read 141 as "namespace absent" → false **FAIL**. Noisy but safe.
- `bar-colour-role-routing` and `bar-colour-alpha-resolution` use `if producer | grep -q`, so 141
  reads as "this file does NOT touch `Colours.*`" → a false **PASS**. That is D-20's gate,
  described in its own check string as "the executable counterpart of this phase's central
  prohibition", able to wave through the exact violation it exists to catch. Demonstrated with a
  synthetic file whose second line is `Colours.surface`: the 3-line version was detected, the
  4000-line version was missed.

Fixed with `_qsd_matches`, which takes the producer's output as a string and matches via
herestring, leaving no upstream process to signal. Applied to the 7 file-scanning assertion
sites; the remaining `| grep -q` uses read tiny fixed-size streams (a busctl list, one printf'd
value, `brightnessctl -l`) where the producer finishes first, and are left alone.

**Bug 2 — stale compliant fixture.** Quick task 260812-69w added the
`bar/BarTooltip.qml|quickshell-bartip-` registry row without adding the matching stub to
`compliant-bar-qml-root/`, so the forward closure counted it missing against every fixture root.
That made `--self-test`'s own **compliant** case fail, and left `missing=1` inside every poisoned
case's result string where it masked the number those cases actually assert on. Stub added,
following the convention `BarDrawer.qml`'s own stub records for quick task 260812-59l.

**Verification — the goal was to keep the gate strict, not to turn it green:**

- `--self-test`: **55 passed, 0 failed** (was 54 passed, 1 failed). All 17 poison detections still
  FAIL correctly, including empty-scan-root (`missing=5`), `poisoned-unregistered-frame`
  (`unregistered=1`) and `poisoned-second-reserving-surface` (`unexpected-reservation=1`).
- Live: `bar-surface-registry` **PASSES** (`rows=5 missing=0`) with the new foot in place, and the
  doctor overall goes 24 passed/4 failed → **25 passed/3 failed**.

## A note on the quickshell restart

The pid changed from `1520318` to `3012973` mid-session. Not a crash and not caused by any edit
here: `journalctl` shows `bar-watchdog: restarted quickshell.service (rc=0)` at 20:38, then
`bar-surface present — no action` at 21:03 — the WINDOWS-row-67 watchdog doing its job after a
monitor event.

## Accent swap (`5752648`)

Operator's call: the permanent accent moves off the settings glyph and onto power.
`settingsTriggerCell` drops `tint: BarRoles.accent` (keeping `filled: settingsExpanded`, so it
still shows open/closed); `powerCell` takes it unconditionally. Recorded in-source as a deliberate
departure from athena, which accents the settings trigger at `style-athena.scss:298` — athena is
GATE-02 Block A's baseline, so the difference had to be marked as chosen rather than drifted.
Not gated on `available`, since `ActionCell` already dims unavailable cells via opacity (verified)
and a conditional tint would leave a host with no power menu showing no accent at all.

## Vertical-orientation pass (`00e90aa`, `23c7d21`, `1787f54`, `df01b56`)

Ran a measured vertical pass at the operator's request. Flipped via
`bar-orientation.sh`, measured with temporary probes (all removed), flipped back with
`reserved=[0,48,0,0]` and `bar x=10 y=6 w=2540 h=42` byte-identical to baseline. Same
process throughout, pid `3012973`, no restart.

**Fixed, each confirmed by measurement:**

| Issue | Before | After |
|---|---|---|
| Dead space in the column | content ended y=1004 of 1420 | start 0→624, end 1016→**1420** |
| `endZone` drawing over `startZone` | both grids `h=1420 sceneY=0` | implicit again (624 / 404) |
| clockActions clipping | `crW=61.3` at `x=-9` in a 44px column | nothing exceeds 44 |
| Popouts/drawers off their trigger | +10px both axes | trigger 786.98 vs popout centre 787 |
| "clock too far right / rest too far left" | cells `x=2` centre 14 | cells `x=9.6` centre 21.6 |
| wifi expansion not revealing bluetooth | `x=-10.8 right=0.0` (clipped away) | `x=20.6 right=31.4` |
| media cropped | `w=44`, title truncated | `w=16` glyph-only, centred |

**Three root causes worth remembering:**

1. **`anchors.x = undefined` does not clear an anchor from inside a binding.** Found in
   `Bar.qml`'s zone containers and again in `MediaConnectivityCapsule`'s bluetooth trigger —
   whose comment explicitly claimed the opposite. In the zone case a surviving `verticalCenter`
   made Qt *derive* height: `top=0 + verticalCenter=710 → h=1420`. Replaced with explicit x/y.
2. **`Grid` defaults to `AlignLeft`/`AlignTop`** and sets no item alignment, so the widest child
   decides where narrow ones sit. This is GATE-02's F1 on the other axis.
3. **`Grid` sizes columns from `implicitWidth`, not resolved `width`** — which is why the percent
   readouts still overhang (below).

**Still open, both measured and commented in-source:**

- brightness/battery percent readouts overhang the column by 3px (`right=47` vs 44). Cause
  isolated: the value Text's `implicitWidth` is its natural extent while its bound width is the
  "100%" reserve, so the box reserves 16. A `childrenRect` fix reached `right=45` but produced
  "Binding loop detected for property implicitWidth" and was reverted.
- workspace numerals sit 3px left inside their slots (`centre=19.0`); the slots themselves
  measure correctly centred at 22.0.

**Declined deliberately:** the audio/wifi reveal strips still grow along the column rather than
leftward. Option B (`BarDrawer`) is wired only into `LauncherCapsule` and `ClockActionsCapsule`.
Relocating a slider and mic cell needs a `Component` plus two `Loader`s and re-plumbing three
external id references, and would risk the measured horizontal invariants ("all three gaps
measure 16.00"). The operator chose to keep the current behaviour.

## Consequence for phase 18

These change the bar, so GATE-02's fingerprint is void again. Iteration 3 must open against a
fresh fingerprint and re-observe all fifteen rows. `18-GATE-02-RECORD.md` was not touched;
`## Deletion Authorisation` still reads `RETIRE-02 BLOCKED` and plan 18-20's deletion commit
remains blocked. Batching all three changes into one task before the sitting was deliberate —
each separate fix would have invalidated the next.
