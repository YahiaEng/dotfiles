---
title: In-shell news source editor UI
trigger_condition: If hand-editing news-sources.json becomes friction in daily use — i.e. you find yourself wanting to add or drop a feed and the edit+stow round trip is the thing stopping you.
planted_date: 2026-08-19
origin: /gsd-explore session for the news-tab quick task
---

# Seed: in-shell news source editor

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
