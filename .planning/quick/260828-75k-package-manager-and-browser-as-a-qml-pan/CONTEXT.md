---
quick_id: 260828-75k
decided: 2026-08-28
---

# Decisions — package manager panel

Study: `.planning/notes/package-panel-studies.html`
Artifact: https://claude.ai/code/artifact/b5a9b93e-9d3a-48ca-b2c6-90c3e16cc6e3

## D-1 — Build D1, D3, D4, D5. Not D2.

Operator pick. **D4 Workbench is the main surface** — the stated goal is an
Octopi replacement, and a Settings page is not that.

My recommendation had been D1+D2 and skip D4; overruled on the real goal.
Recorded because the reasoning matters: D4's extra ~600 lines buy bulk
selection and a `pactree` removal preview, which is exactly what "replace
Octopi" requires and what a Settings page cannot fake.

## D-2 — D1 is rescoped to a thin preferences page.

With D4 in the tree, D1 as drawn (chips + list + `-Qi` detail) is the same
browser in a second frame — the redundancy that got the Security Center's two
layouts merged in operator round 3.

D1 ships as: "Open package manager" → D4, plus the prefs — check interval
(MOVED here from the Services page), include-AUR, orphan warning, bar capsule
visibility, confirm-in-terminal. No list. No detail pane. ~200 lines.

## D-3 — D5 REPLACES the existing updates capsule; it does not add one.

Operator correction, verified in code. The study was wrong to call this a new
capsule with a bar-reflow risk. The readout already exists:
`modules/bar/SystemCapsule.qml:509`, a `Readout` with glyph
`deployed_code_update`, filled tertiary pill (`BarRoles.fillUpdates`), hidden
at zero, single-flighted 30-min poll (`services.updatesPollMs`), click →
`launchUpgrade()` → kitty on `paru -Syu` → `notify-send`.

Two real defects it fixes:
1. **AUR-blind.** Polls `checkupdates` only, so `pendingUpdatesCount` counts
   repo updates alone. Measured 2026-08-28: shows **3** while **4** are
   pending (`python-steam` invisible).
2. **No preview.** A click starts the full upgrade with no way to see what
   changes first. The popout fixes this.

Everything else about the cell stays: glyph, pill colour, hide-at-zero,
single-flighting, poll interval, terminal handoff.

## D-4 — One backend. `PackagesBackend.qml` singleton.

Sibling of `SecurityBackend.qml`. Owns the `pacman -Qi` dump, repo list,
updates, orphans, history. Every surface reads it; none shells out on its own.
One instance survives page navigation so a long operation is not killed.

Enabled by measurement: `pacman -Qi` returns all 1420 packages with every
field in **0.20s / 1.33MB**. No incremental load, no cache file, no daemon.

## D-5 — Terminal handoff for every write. No privileged install.

No pkexec verb, no polkit action, no `install.sh` change, nothing in
`section_security`'s shape. A package transaction's whole value is that pacman
prints what it will do and asks — wrapping that in a polkit dialog replaces a
good confirmation with a worse one.

Precedent: `UpdatesPage.qml` and `SystemCapsule.qml:588` both already do this.

## D-6 — D4 absorbs UpdatesPage.qml.

347 lines retired rather than run a second package surface beside D4. One
owner for the update action; the capsule and the `pkg` route link into D4.

## D-7 — Octopi comes off the disk once D4 is operator-confirmed.

`octopi-git`, plus `qt-sudo` / `qtermwidget` if nothing else claims them
(check with `pacman -Qo` / `pactree -r` first — the retiring-a-package rule).
Installed 2026-08-28 03:50, which is what prompted this task.

## Open — not decided

- Row treatment (R1/R2/R3) was never answered. Defaulting to **R1 ledger** for
  D4's table since it is a sortable table of names/versions/sizes; revisit if
  the operator says otherwise on first render.
- D2 Sentinel not built. The footprint plate is the part worth keeping in mind
  if a dashboard tab is ever wanted.
