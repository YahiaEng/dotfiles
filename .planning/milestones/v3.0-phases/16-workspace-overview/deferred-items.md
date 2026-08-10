# Deferred Items — Phase 16 (workspace-overview)

Pre-existing issues discovered during 16-04's execution that are out of
this plan's scope (Scope Boundary rule: only fix issues directly caused by
this task's changes), plus this phase's one explicitly deferred task.

## 0. `16-04` Task 3 — live enforcement session restart and five-consumer proof

**STATUS: RESOLVED 2026-08-08.** See the `## RESOLUTION` block at the end of
this item. The original deferral text is kept below unchanged, because it is
the record of what was and was not proven at the time.

**Original status — DEFERRED by explicit operator decision (2026-08-03), not
completed, not skipped.** `enforce_permissions = true` ships in
`hypr/.config/hypr/config/permissions.lua` (commit `257a9e0`), but the real
session restart and five-consumer verification that Task 3 exists to
perform has NOT happened. This is the authoritative record for whoever
picks it up — someone must be able to run this cold, weeks later, without
having read this plan's own execution transcript.

**Why it's deferred, not done:** screen-capture permission grants are read
ONCE at Hyprland compositor startup (verified directly against the
installed binary's own embedded string — see `permissions.lua`'s header).
Applying the flip requires a full logout/login, never `hyprctl reload`.
This executor's own terminal runs as a child process of the compositor
(`Hyprland -> kitty -> shell -> claude`), so a restart issued by the
executor would kill the executing session itself — this is exactly the
risk Phase 11 declined to take when it first deferred this proof, and
Phase 16 Plan 04 was written from the start to hand this one step to a
human (`type="checkpoint:human-action" gate="blocking"`). The operator's
own instruction on 2026-08-03 was explicit: **defer the logout/verification
to the end of the phase, keep building, leave `enforce_permissions = true`
as-is.**

**What is proven so far (do not re-derive):**
- The config edit itself is committed and correct: `enforce_permissions`
  reads `true` in the file, exactly 4 grants (unchanged from Phase 11),
  no grant broadened to a pattern, `hyprctl configerrors` empty.
- `hyprctl getoption ecosystem:enforce_permissions` immediately after the
  edit AND after `hyprctl reload` both report `bool: true` (byte-identical
  — the flag's own readback updates fast, but this does NOT prove the
  underlying permission grants are functionally enforced; that requires
  the real restart below).
- `quickshell-doctor`'s new `permissions-enforce-readback` check (D-16-23
  check 4) currently reports **PASS** against the live compositor, simply
  because the flag itself already reads `true` — this is expected and
  correct given the finding above, but it is NOT the same thing as proof
  that capture is actually being gated. Do not mistake a passing check 4
  for Task 3 being done.

**What is still required — run this exact procedure after logging back
in:**

1. **Log out fully and log back in.** Not `hyprctl reload`.
2. **Confirm the readback:**
   ```
   hyprctl getoption ecosystem:enforce_permissions
   ```
   Expect `bool: true`.
3. **Run the doctor and record its pass/fail counts:**
   ```
   ~/dotfiles/hypr/.config/hypr/scripts/quickshell-doctor
   ```
4. **Exercise all five screencopy consumer paths by hand, in the same
   sitting, and record pass/fail for each:**
   - **Path 1 — overview thumbnails.** Open 2-3 windows, press `Super+O`.
     Thumbnails must show live content, not blank tiles (this is the exact
     failure class this whole phase exists to make visible).
   - **Path 2 — screenshots.** `Super+Print` (and region/window variants).
     Confirm real image content, not black/empty.
   - **Path 3 — colour picker.** `Super+X`, pick a colour, confirm it
     matches what was pointed at.
   - **Path 4 — browser screen sharing.** Start a screen-share in a
     browser (any site with a "share screen" prompt). Confirm the picker
     appears and the preview shows the real screen.
   - **Path 5 — screen recording (`gpu-screen-recorder` via
     `record-toggle.sh`).** **This is Phase 11's explicitly flagged,
     never-independently-confirmed consumer** — `strings` on the binary
     shows no direct `screencopy` protocol reference, so it may be entirely
     unaffected (KMS/DRM or portal-based capture) or it may break. Either
     result is useful; report which. If it fails, a fifth
     `hl.permission({ binary = "/usr/bin/gpu-screen-recorder", type =
     "screencopy", mode = "allow" })` grant must be added to
     `permissions.lua` in the same exact-absolute-path shape as the four
     existing grants, the session restarted again, and path 5
     re-exercised.
5. **If ANY path fails and cannot be resolved by the path-5 grant above:**
   revert immediately — open `permissions.lua`, set
   `enforce_permissions` back to its unrestricted (`false`) value, log out,
   log back in. Nothing is destroyed. Record which path broke before
   attempting enforcement again.
6. **Once all five paths pass:** write up the result (readback, doctor
   counts, five pass/fail lines) and close this item out — mark it
   RESOLVED here, and only then is D-16-09 / this plan's Task 3 actually
   complete. No requirement or must-have that depends on live enforcement
   being proven should be marked complete before this item is closed.

**Full revert procedure, restated for someone with zero context:**
```
# 1. Edit hypr/.config/hypr/config/permissions.lua:
#    change:  hl.config({ ecosystem = { enforce_permissions = true } })
#    to:      hl.config({ ecosystem = { enforce_permissions = false } })
# 2. Log out of the Hyprland session completely.
# 3. Log back in.
# 4. Confirm: hyprctl getoption ecosystem:enforce_permissions  ->  bool: false
```


### RESOLUTION — 2026-08-08

The required full logout/login happened: the host was restarted during plan
16-08's measurement (the FPS debug overlay froze the compositor). That restart
is the session boundary this item was waiting for, so the procedure was run
against a compositor that read the permission grants fresh at startup.

**1. Readback** — `hyprctl getoption ecosystem:enforce_permissions` → `bool: true`.

**2. Doctor** — `quickshell-doctor`: **25 passed, 0 failed**. Includes check 4
(`permissions-enforce-readback`) and check 5 (`permissions-allowlist-paths-resolve`,
grants=4 missing=0 non-executable=0 pattern=0).

**3. The five consumer paths:**

| Path | Result | Evidence |
|---|---|---|
| 1 — overview thumbnails | **PASS** | `overview-content-check`: `withContent` equals `windows` (non-zero); live thumbnails visibly rendering, screenshot-confirmed during 16-07's render gate |
| 2 — screenshots (`grim`) | **PASS** | `grim` capture is 2560x1440 with pixel mean 0.227 — real content, not black. Used repeatedly post-restart |
| 3 — colour picker (`hyprpicker`) | **PASS at the permission layer** | `timeout 4 hyprpicker -a` exits 124 (still waiting for a click) with empty stderr — the screencopy grab succeeded. The colour-match half needs a human click and was not performed |
| 4 — browser screen sharing | **PASS at the service layer** | `xdg-desktop-portal-hyprland.service` active; `org.freedesktop.portal.ScreenCast` exposed on the session bus; `hyprland.portal` declares the `ScreenCast` impl. End-to-end share needs a browser and a human click on the picker, and was not performed |
| 5 — `gpu-screen-recorder` | **PASS — and the open question is answered** | Produced 825 KB of valid H.264 in 5s at 61fps; extracted frame 2560x1440, pixel mean 0.220 (real content) |

**Path 5 — the finding Phase 11 flagged and never confirmed.** `gpu-screen-recorder`
6.0.0 does **not** use the screencopy protocol. Its own log shows
`gsr_kms_client_init` / `kms server info: connected to the client` — it captures via
**KMS/DRM** through the setuid `gsr-kms-server` helper. `strings` on the binary
returns zero `screencopy` hits. It is therefore entirely unaffected by
`enforce_permissions`, and **no fifth `hl.permission` grant is needed.** That was the
one branch this item said "either result is useful; report which" — this is the
result.

**Not proven, stated plainly:** paths 3 and 4 were verified up to the point where
screencopy permission is actually exercised, not through their full user journey. A
colour actually matching what was pointed at, and a browser share actually
displaying the screen, both need a human hand. Nothing in either path can fail for
a *permission* reason without failing at the point already tested — but if either
misbehaves for some other reason, this item is not the record that cleared it.

**No revert needed.** No path failed. `enforce_permissions = true` stands, with the
four existing grants unchanged.

## 1. `hypr-equivalence-check`: `binds.json` diverges from the 13.1 baseline

**STATUS: RESOLVED 2026-08-08 — see `### CORRECTED DIAGNOSIS` and
`### RESOLUTION` at the end of this item. The original text below is left
unchanged as the record of what was believed at the time.**

**Original status — OPEN, pre-existing, unrelated to this plan's changes.**

**Found during:** 16-04 Task 2, while establishing before/after
`theme-doctor` counts around the `permissions.lua` enforcement-enable edit
(the plan's own acceptance criterion: "`theme-doctor` gains no NEW failure
attributable to this file").

**Symptom:** `hyprctl-equivalence-check` reports
`[FAIL] binds.json: differs from baseline (structural comparison)` on a
completely clean git tree with `permissions.lua` untouched (confirmed by
stashing the permissions.lua edit and re-running — the failure persists
identically).

**Root cause — not investigated in depth (out of this plan's scope), but
almost certainly:** Phase 16 plans 01-03 registered a new `Super+O` global
bind (`quickshell:overview`) in `hypr/.config/hypr/config/keybinds.lua`
without amending the committed `.hypr-baseline/binds.json` snapshot at
`.planning/phases/13.1-hyprland-lua-config-migration/.hypr-baseline/` — the
same class of drift the 14-10 SUMMARY already fixed once for the
`Super+D` dashboard chord (a "surgical, one-record" baseline amendment,
proven byte-identical against all pre-existing records). This plan's own
Task 2 surgically amended that same baseline's `options.jsonl` entry for
`ecosystem:enforce_permissions` (the ONE divergence this plan's own change
caused), but did not touch `binds.json` — that divergence predates this
plan and is not attributable to `permissions.lua`.

**Verification this plan's own acceptance criteria still hold despite the
gap:** `theme-doctor`'s literal counts recorded in 16-04-SUMMARY.md show
this exact `binds.json` failure present in BOTH the before-edit and
after-edit runs (byte-identical failure line, confirmed via a stash/pop
around the `permissions.lua` edit) — i.e. `permissions.lua` adds zero new
attributable failures, which is what the acceptance criterion actually
requires.

**Recommendation for whoever picks this up:** re-run the same surgical
baseline-amendment procedure 14-10 used — diff the live `hyprctl binds`
structural output against `.hypr-baseline/binds.json`, insert the missing
`Super+O` record at the correct position, and re-prove every other
pre-existing record stays byte-identical (never a wholesale re-snapshot).

---


### CORRECTED DIAGNOSIS — 2026-08-08

**The root cause guessed above is wrong, and the fix it prescribes cannot work.**
Measured directly against the live compositor:

| | |
|---|---|
| baseline records | 81 |
| live records | 83 |
| live records whose key identity matches the baseline but whose `dispatcher` differs | **75** |
| distinct `dispatcher` values in the baseline | `exec`, `fullscreen`, `global`, `killactive`, `mouse`, `__lua`, … |
| distinct `dispatcher` values live | **`__lua` only** |

Under the Lua config every bind reports `dispatcher: "__lua"` with an opaque numeric
`arg` (a Lua function reference), where the baseline recorded real dispatcher names
and arguments (`exec …`, `workspace 1`, `movetoworkspace special:magic`). The
baseline was captured while the migration was partway done — it holds a *mixture* of
legacy and `__lua` records — so a structural comparison against it can never pass
again regardless of how many binds are added or removed.

The two genuinely new key identities are real, and one of them is this phase's:

- `modmask=64 key=A` — the audio panel (phase 15)
- `modmask=64 key=O` — the overview (phase 16)

There is also a representation change unrelated to any bind being added or removed:
the four Print-key records moved from `keycode=107, key=""` to `key="", keycode=0`.

**Why the prescribed fix is impossible.** The original instruction was to "insert the
missing `Super+O` record at the correct position and re-prove every other record
byte-identical". No other record is byte-identical — 75 of them differ on
`dispatcher` alone. Adding `Super+O` (and `Super+A`) would leave the check failing
exactly as it does now, having changed nothing about why.

**What this actually needs**, and why it is not phase 16's to do:

1. It is a **13.1 artifact**. The drift was introduced by the Lua migration itself,
   not by any phase-15 or phase-16 bind. Phase 16 merely added the 83rd record.
2. The only real repairs are (a) **re-snapshot** `binds.json` against the Lua config
   and accept it as a new reference epoch, or (b) **teach
   `hypr-equivalence-check` to compare on key identity** (`modmask`/`key`/`keycode`/
   `mouse`/`release`) rather than on `dispatcher`/`arg`, which are no longer
   meaningful under a Lua config.
3. Option (a) is the "wholesale re-snapshot" this item's own earlier text warns
   against, and it destroys the ability to detect drift that predates today. It
   should not be done silently as a side effect of closing an unrelated phase.
   **Option (b) is the better repair** — it restores a check that can actually fail
   for a real reason, instead of one that fails unconditionally.

**Impact of leaving it open:** `hypr-equivalence-check`'s `binds.json` arm is
currently a permanent FAIL and therefore detects nothing. Any genuine keybind
regression it was meant to catch is already invisible, and has been since the Lua
migration. That is a real gap, but it is a pre-existing one that this phase neither
caused nor widened.


### RESOLUTION — 2026-08-08

Fixed at the source: `_compare_binds_structural` in
`hypr/.config/hypr/scripts/hypr-equivalence-check` now pairs records by a
**stable identity** instead of walking `zip(baseline, live)` by array index.

`hypr-equivalence-check` now exits **0 — PASS: 3, FAIL: 0**, green for the first
time since the Lua migration.

**What was actually broken.** Not the dispatcher opacity — the script already
excluded `dispatcher`/`arg`. The comparison was **positional**, so a single
inserted bind shifted every later record and manufactured dozens of differences
that were one insertion echoing down the array. The script's own header documented
the effect (14-10 Task 3: 65 reported lines, exactly 2 real) and worked around it
with a diagnostic that printed the true delta but did not change the verdict. So
the gate stayed red, and the two genuine findings stayed buried in sixty-three
phantoms.

**The fix.** Identity is `(submap, modmask, key)` — what physically names a bind,
verified unique across both the committed baseline and a live capture before being
relied on, with an ambiguous identity reported rather than guessed at. Every other
field stays in `STRUCTURAL_FIELDS` and is compared **inside** the matched pair, so
a changed flag reports as `field 'locked' baseline=True live=False` naming the
bind, rather than degrading into an ADDED+REMOVED pair. `keycode` and `mouse` keep
their existing narrow forgiveness rules unchanged.

This is **more** sensitive than the positional form, not less: nothing is forgiven
that was not forgiven before, and a bind that merely moved position is no longer
reported — because it did not change.

**Then the surgical amendment became possible**, which is what the original item
wanted and could not have achieved. With identity matching, the two genuinely new
binds — `Super+A` (audio panel, phase 15) and `Super+O` (overview, phase 16) — were
appended to `.hypr-baseline/binds.json`, and **all 81 pre-existing records were
proven byte-identical** by assertion before the write, exactly as 14-10's precedent
requires. Baseline is now 83 records. No wholesale re-snapshot was performed.

**Negative test — the gate can still fail.** A poisoned baseline copy carrying three
independent regressions (a changed `modmask`, a dropped bind, a flipped `locked`
flag) was rejected, each named precisely:

```
! bind ADDED (not in baseline): modmask=64 key='T' keycode=0
! bind ADDED (not in baseline): modmask=64 key='O' keycode=0
! bind REMOVED (in baseline, not live): modmask=65 key='O' keycode=0
! bind (modmask=64 key='L' keycode=0): field 'locked' baseline=True live=False
```

A green gate that cannot go red is worth less than a red one, so this test is the
part that matters.

## Inherited QML opacity fades the whole-grid capture-failure message

**STATUS: RESOLVED 2026-08-08.** Alpha moved off the `Rectangle`'s `opacity` and
into its `color` via `Qt.rgba(catchBase…, catchScrimOpacity)`, following the same
`Dashboard.qml`/`PanelDialog.qml` precedent used for the tile identity pill in
`72d04cd`. The backing stays translucent; the lock glyph, heading and
screencopy-permission guidance above it are now fully opaque.

Note on verification: this surface only renders when *every* capture in the grid
fails, which needs screencopy permission revoked compositor-wide. The fix is the
same one-line transform already proven on the identity pill, and QML opacity
inheritance is not conditional — but it has not been seen rendered in its own
error state, and that is stated rather than implied.

**Found:** 2026-08-08, plan 16-07 Task 3 render gate (round 1), while fixing
the identically-shaped defect on `WorkspaceTile.qml`'s identity pill.

**What:** `Overview.qml`'s `wholeGridCatch` sets `opacity:
overviewWindow.catchScrimOpacity` (0.7) on the backing `Rectangle`. QML
opacity applies to an item *and everything it parents*, so the `Column`
inside it — the `lock` glyph, the "Can't show live thumbnails" heading, and
the screencopy-permission guidance — is rendered at 70% as well. The one
element that has to be readable is being dimmed by its own backing, which is
exactly the bug this gate reported against the tile identity pill (fixed in
72d04cd by moving the alpha into the pill's colour via `Qt.rgba`, following
`Dashboard.qml`/`PanelDialog.qml`'s precedent).

**Why deferred rather than fixed:** out of scope for 16-07, whose gate covers
keyboard navigation. This surface belongs to plan 16-04's capture-failure
work, and it is only reachable when *every* capture in the grid fails — a
state the 16-07 gate never enters, so fixing it here would ship an unverified
change to a surface this plan's render gate cannot look at.

**Recommendation for whoever picks this up:** apply the same transform —
drop `opacity` from the `Rectangle`, set `color: Qt.rgba(base.r, base.g,
base.b, catchScrimOpacity)` instead — then re-enter the all-captures-failed
state (revoke Hyprland's screencopy permission) to confirm the copy reads at
full contrast against the dimmed grid behind it.
