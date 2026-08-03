# Deferred Items — Phase 16 (workspace-overview)

Pre-existing issues discovered during 16-04's execution that are out of
this plan's scope (Scope Boundary rule: only fix issues directly caused by
this task's changes), plus this phase's one explicitly deferred task.

## 0. `16-04` Task 3 — live enforcement session restart and five-consumer proof

**STATUS: DEFERRED by explicit operator decision (2026-08-03), not
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

## 1. `hypr-equivalence-check`: `binds.json` diverges from the 13.1 baseline

**STATUS: OPEN, pre-existing, unrelated to this plan's changes.**

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
