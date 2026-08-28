---
quick_id: 260828-75k
slug: package-manager-and-browser-as-a-qml-pan
date: 2026-08-28
status: built-awaiting-operator
commits:
  - 8ab83760  # design study, five directions
  - 5c42c89a  # decision record: D4 main, D1 rescoped, D5 repairs
  - 8dfc9f24  # PackagesBackend + bar count fix
  - 36358e9d  # D4 workbench
  - a919de9b  # D5 popout
  - 3fd055bd  # D3 launcher `+` route
  - 6ad0e674  # D1 settings page
artifact: https://claude.ai/code/artifact/b5a9b93e-9d3a-48ca-b2c6-90c3e16cc6e3
operator_status: NOT YET VERIFIED — four surfaces built, two decisions open
---

# Package manager & browser as a QML panel

Four surfaces over one backend, replacing Octopi.

## What shipped

| Piece | File(s) | State |
|---|---|---|
| Backend | `modules/packages/PackagesBackend.qml` | verified over IPC |
| D4 workbench | `Workbench/WbSidebar/WbTable/WbDetail/WbButton.qml` | rendered + captured |
| D5 popout | `modules/packages/UpdatesPopout.qml`, `bar/SystemCapsule.qml` | rendered + captured |
| D3 `+` route | `modules/packages/PkgMode.qml`, `launcher/*` | loads; typed query UNVERIFIED |
| D1 settings | `modules/settings/pages/PackagesPage.qml` | rendered + captured |

## The defect that started as a feature request

The bar's updates pill was **AUR-blind**. `SystemCapsule.qml` polled
`checkupdates` alone, so `pendingUpdatesCount` counted repo updates only —
measured 2026-08-28, it read **3** while **4** were pending, with
`python-steam` invisible. Now `PackagesBackend.pendingCount`, verified 4.

## Measurements that shaped the design

- `pacman -Qi` → all 1420 records, every field, **0.20 s / 1.33 MB**; JS parse
  ~0.19 s. So no cache file, no daemon, no incremental load.
- `pacman -Sl` → 15,412 entries in **0.17 s**. Cheap enough to load at startup,
  which is what fixed the Source column.
- `pacman -Rs --print --print-format '%n %v'` resolves the **full removal
  cascade without root**. 6 orphans → **11 actual removals**, 113 MiB.
- `checkupdates` 0.81 s, `paru -Qua` 0.90 s. Only these two are behind a
  "checking" state.
- `expac` is NOT installed and nothing here needs it. No new package.

## Things that were wrong and how they were caught

1. **Source column read "local" for every repo package** — catalogue was
   deferred; "local" is a specific pacman word, so the fallback was wrong, not
   merely vague. Caught on first render.
2. **Refuse message lost its useful half** — pacman writes `error:` to stderr
   but the `:: … required by X` reasons to **stdout**. Caught by running the
   refuse path.
3. **`_fields()` declared below its construction-time caller** — the recorded
   "not a function" trap.
4. **Directory-scanner synthesis does not see new files.** `modules/bar/` and
   `modules/launcher/` have no explicit qmldir; a type added there reads "is
   not a type" and takes the whole config down, and NO number of hot reloads
   fixes it. Both new types live in `modules/packages/` for this reason.
   A919de9b's commit message got this wrong and 3fd055bd corrects it.
5. **`compSlugs` + a stale RowIndex entry** — both caught by
   settings-index-check, not by me.

## Gates

colour-lint 542/0 · motion-lint 727/0 · qml-import-check 0 unresolved /182
files · settings-index-check 196/0 · hot reload `Configuration Loaded` clean.

`quickshell-doctor` NOT run — it restarts the shell from inside, operator-only.

## Open — needs the operator

See the handover checklist in the session. Two decisions deliberately NOT
taken unilaterally because both are destructive:

- **D-6, retire `UpdatesPage.qml`** (347 lines). Recorded at pick time, but the
  workbench does **not** cover its per-package armed single-update, so
  retiring it loses a capability. Wants an explicit call.
- **D-7, remove Octopi.** `octopi-git` + `qt-sudo` + `qtermwidget`. Only after
  the workbench is confirmed working, and only after `pacman -Qo` /
  `pactree -r` confirm nothing else claims the two dependencies.
