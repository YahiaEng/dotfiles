---
title: In-shell news source editor UI
trigger_condition: If hand-editing news-sources.json becomes friction in daily use — i.e. you find yourself wanting to add or drop a feed and the edit+stow round trip is the thing stopping you.
planted_date: 2026-08-19
origin: /gsd-explore session for the news-tab quick task
---

# Seed: in-shell news source editor

> **PROMOTED AND SHIPPED 2026-08-19** — quick task `260819-pi3`
> (`.planning/quick/260819-pi3-in-shell-news-source-editor-ui-for-the-n/`).
> Kept for its rationale, which is still accurate; the deferral it argues for
> no longer applies.
>
> Shipped: the manage-sources surface, per-source enable/disable, delete, add
> by URL, **live feed-probing** and **editable display names**. The last two
> were initially cut as out-of-quick-scope and then restored by the operator
> mid-flight — which is what took the plan to 4 tasks.
>
> Still deferred: **drag-to-reorder** (the mockup's `≡` handles). Headlines
> sort by date and selection is round-robin by source, so list order affects
> tie-breaks only.
>
> Two details below are now stale: the mockup lists NPR (dropped in
> `260819-m94` over a tracking-pixel-first image path), and the name is
> seeded from the feed's own title rather than typed blind.

## What was deferred

During news-tab exploration, three source-management options were weighed:

1. Fixed built-in array in QML (rejected — mixes config into shell source)
2. **Seeded hand-editable `news-sources.json`** ← chosen
3. Full in-shell add / remove / reorder UI ← **this seed**

Option 3 was deferred because it roughly doubles the task: it needs a text input
surface, URL validation, live feed-probing to confirm a pasted URL actually parses,
reorder affordances, delete confirmation, error states, and persistence — which
pushes the work out of quick-task range and into phase territory.

## What it would look like

```
┌────────────────────────────────┐
│  Notifications  ·  News     ⌫  │
├────────────────────────────────┤
│  [ BBC World        ▾ ]   ⚙   │
├────────────────────────────────┤
│  MANAGE SOURCES                │
│  ┌──────────────────────────┐  │
│  │ BBC World         ≡  ✕  │  │
│  │ NPR               ≡  ✕  │  │
│  └──────────────────────────┘  │
│  [ paste feed URL…      ] [+]  │
│  ⚠ validating feed…           │
└────────────────────────────────┘
```

## Why it is cheap to add later

The chosen architecture does not block it. `news-sources.json` is already the
single source of truth read through a watched `FileView` — an editor UI would
just *write* that same file rather than requiring a new storage design. The
validation step also already exists in spirit: the feed walker returns a parsed
item count, so "does this URL work?" is answerable by running the walker against
the pasted URL and checking for a non-zero count.

## Prerequisite

The news tab itself must ship first, with `news-sources.json` registered in
`theme-engine/contract.json`.
