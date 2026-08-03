# Deferred Items — Phase 16 (workspace-overview)

Pre-existing issues discovered during 16-04's execution that are out of
this plan's scope (Scope Boundary rule: only fix issues directly caused by
this task's changes).

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
