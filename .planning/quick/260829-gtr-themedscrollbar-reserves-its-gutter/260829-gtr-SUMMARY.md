---
quick_id: 260829-gtr
title: ThemedScrollBar reserves a gutter instead of overlaying content
status: complete
completed: 2026-08-29
commits: [21220a56]
gates: "colour-lint 572/0; quickshell-doctor 28/0"
---

# 260829-gtr — SUMMARY

## What the operator asked

"The scrollbar on the left side of the settings menu is clipping with the menu
items."

## Confirmed on pixels before editing

`grim` region capture of the settings window, raw RGB run-dump across the rail:

| region | x-range | what |
|---|---|---|
| nav row pill | 8 – **588** | `surfaceContainerHigh` fill |
| **scroll bar** | **581 – 584** | inside the pill |
| pill remainder | 585 – 588 | 8px of pill to the bar's right |
| rail gutter | 589 – 596 | rail background |

The bar painted on the row, 8px short of the pill's own edge. Cause in code:
`anchors.right: flickable.right` with `z: 100` and nothing reserving width.

## Not a rail bug — a component bug

`ThemedScrollBar` has **20 consumers**, all using the identical minimal form
`ThemedScrollBar { flickable: X }`. Every one of them had the same overlay. Fixed
at the component so the population is fixed at source rather than the one
surface the operator happened to be looking at.

## Why reserving on the Flickable is the right lever

Enumerated all 20 before choosing: every consumer anchors its Flickable's right
edge to a parent (via `anchors.fill` or an explicit `anchors.right`) and **not
one** sets an explicit `width`. So narrowing the Flickable propagates to every
content binding for free — a Column at `width: flick.width`, a delegate at
`ListView.view.width`, all of it — with zero call-site changes.

## The additive margin is not optional

Two consumers (`PageBase`, `PanelDialog`) set `anchors.margins` for their own
padding. In Qt a specific `anchors.rightMargin` **overrides** `anchors.margins`
for that edge, so assigning the gutter alone would have silently deleted their
padding. The reservation reads the effective margin first and adds to it, and is
guarded by `_reserved` so a hot reload cannot grow the margin 12px per save.

## Measured after

| | pill ends | bar | overlap |
|---|---|---|---|
| before | 588 | 581–584 | bar inside pill |
| after | **576** | 581–584 | **none** — 4px clear left, 12px right |

Visually confirmed on a NEAREST-upscaled crop: the bar sits in its own gutter,
clear of the rounded pill corners.

## Trap worth keeping — the watcher dies with the inode

The fix appeared not to work three times running. It had: **quickshell had
stopped hot-reloading entirely.** An editor that writes via temp-file + rename
gives the file a new inode, and the inotify watch on the old inode is now dead —
so no reload fires, and *no subsequent edit to that file fires one either*,
including an in-place append. The log's last write predating the edit is the
tell; a stale-looking screenshot is not evidence your change is wrong.

Recovery is a `systemctl --user restart quickshell.service`. That was taken only
after measuring that it was safe: this session's shell sits in
`kitty-315432-0.scope` and quickshell in `quickshell.service` — **disjoint
cgroups**, so a unit restart cannot reach the agent's session. Measured, per the
standing rule, rather than deferred on reputation.
