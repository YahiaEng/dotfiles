# hypr-equivalence-check baseline manifest

- hyprctl version: Hyprland 0.56.1 built from branch v0.56.1 at commit 5c9377c15f85c50648f35ca5a213754f95b93ca0 clean (version: bump to 0.56.1).
- config format at capture time: hyprlang (.conf) — pre-migration (D-09)
- git commit: 7ea6ba5b012d73107cfd47b6377126124992e5c4
- capture timestamp (UTC): 2026-07-28T02:24:18Z
- option keys extracted (parsed from the 8 config files at run time, not hardcoded): 46
- binds.json bind count: 80
- options.jsonl record count: 46
- uncovered.txt entry count: 8 (4 permission-grant entries from 13.1-01; 4 binds.json field entries added by 13.1-04 Task 3 — see COVERAGE.md's "binds equivalence: two-half proof" section for the full picture)

## Documented coverage limits (D-16)

One line per key/declaration this gate cannot (or structurally does not) introspect
via `hyprctl getoption`/`hyprctl -j binds`, with the reason and its named compensating check:

- `permission-grant:/usr/bin/quickshell, screencopy, allow` — permission grants are read once at Hyprland startup and are not exposed via hyprctl getoption — no per-grant introspection key exists; compensating check: recorded side-by-side textual review in plan 13.1-07
- `permission-grant:/usr/bin/grim, screencopy, allow` — permission grants are read once at Hyprland startup and are not exposed via hyprctl getoption — no per-grant introspection key exists; compensating check: recorded side-by-side textual review in plan 13.1-07
- `permission-grant:/usr/bin/hyprpicker, screencopy, allow` — permission grants are read once at Hyprland startup and are not exposed via hyprctl getoption — no per-grant introspection key exists; compensating check: recorded side-by-side textual review in plan 13.1-07
- `permission-grant:/usr/lib/xdg-desktop-portal-hyprland, screencopy, allow` — permission grants are read once at Hyprland startup and are not exposed via hyprctl getoption — no per-grant introspection key exists; compensating check: recorded side-by-side textual review in plan 13.1-07
- `binds.json:dispatcher` — opaque (`"__lua"`) for every Lua-registered bind; compensating check: `keybind-source-equivalence` (13.1-04 Task 3)
- `binds.json:arg` — opaque (internal index) for every Lua-registered bind; compensating check: `keybind-source-equivalence` (13.1-04 Task 3)
- `binds.json:keycode` (code:NNN binds only) — reads back 0, not the real keycode; compensating check: physical keypress at end-of-phase human verification
- `binds.json:mouse` (bindm binds only) — reads back false, not true; NOT MECHANICALLY VERIFIABLE, left un-loosened (a real, currently-failing structural check outcome); compensating check: physical mouse-drag at end-of-phase human verification

## Amendment — 14-10 Task 3 (2026-07-30)

**Plan `14-10-PLAN.md` (Phase 14, "dashboard-drawer"), Task 3.** This baseline
was amended by a **one-record surgical insertion, not a re-snapshot**. The
distinction matters: a re-snapshot would have overwritten every one of the
80 pre-existing records with fresh live values, including the two
`bindm` mouse-field records this same file's own coverage-limits section
(above) explicitly forbids loosening ("does NOT tolerate this divergence
(no loosening, per 13.1-04 Task 3's explicit instruction)"). A surgical
insertion touches exactly the one record diagnosed as a genuine addition
and leaves everything else — including that un-loosened divergence —
completely untouched, so the forgiveness this same task adds to the gate's
own comparator (see `hypr-equivalence-check`'s `MOUSE_FORGIVEN_KEYS`) rests
on an explicit, provisional rule in the gate itself, never on a baseline
value quietly overwritten to match.

**Why the gate was red before this amendment.** `hypr-equivalence-check`
reported a bind count mismatch of exactly one (baseline 80, live 81) and 65
positional difference lines. Two independent causes, not one:

- **The stale baseline.** This committed baseline predates Phase 14. Phase
  14 Plan 01 registered a new global bind — `SUPER+D` dispatching
  `quickshell:dashboard` (`quickshell/.config/quickshell/shortcuts.json`,
  `hypr/.config/hypr/config/keybinds.lua` — see `14-01-SUMMARY.md`) — which
  the live compositor now reports at array index 30 and this baseline never
  recorded. Every one of the 63 remaining positional difference lines was
  the SAME single-record insertion rippling through an index-based
  positional comparison; not 63 independent findings.
- **The pre-existing mouse-field divergence.** The two `bindm` records
  (`mouse:272`/`mouse:273`) already diverged on the `mouse` field before
  this plan ever touched anything — see the coverage-limits entry above,
  recorded by Phase 13.1 and explicitly left un-loosened.

**The bound: an order-insensitive delta, computed BEFORE anything was
written.** Keyed on exactly the gate's own 15 structural fields
(`dispatcher`/`arg` excluded because the gate excludes them — the Lua shim
indirection; `keycode` excluded because the gate forgives it separately,
via its own 107-vs-0 rule, and folding it into the identity would have
manufactured four phantom additions plus four phantom removals against the
four baseline records that carry a real pre-migration keycode). The
baseline's 80 records were confirmed to produce 80 distinct identities
under this key (no duplicates) before the delta was trusted. Full result:

```
ADDED (in live, not in baseline):    1 record — key="D", modmask=64 (SUPER+D)
                                      1 record — key="mouse:272", mouse=false
                                      1 record — key="mouse:273", mouse=false
REMOVED (in baseline, not in live):  1 record — key="mouse:272", mouse=true
                                      1 record — key="mouse:273", mouse=true
```

Every record in that five-line delta is accounted for: the `D` addition is
the one legitimate new bind, and the `mouse:272`/`mouse:273` pairs appear as
both added and removed only because their identity changed on the single
`mouse` field already named above — not because they are new binds. Nothing
in the delta was unaccounted, so nothing halted the task and the amendment
proceeded.

**The amendment.** Exactly one record — the `SUPER+D` bind, taken verbatim
from the live capture — inserted at array index 30, the same index the live
capture holds it at. All eighty pre-existing records were verified
byte-identical before and after the insertion (a direct byte-level diff of
the file with that one record removed reproduces the pre-amendment file
exactly; the four records carrying a real pre-migration keycode are among
those eighty and remain untouched, so the gate's keycode-forgiveness branch
stays live rather than becoming dead code). Neither `animations.json` nor
`options.jsonl` was touched — both already pass and there was nothing to
fix in them.

**Provenance of the inserted record — a post-migration artifact, inserted
verbatim rather than fabricated.** Every one of the eighty pre-existing
records was captured on 2026-07-28, pre-migration, and so carries real
pre-migration dispatcher/argument values in its `dispatcher`/`arg` fields.
The `SUPER+D` bind did not exist pre-migration — it was added by Phase 14
Plan 01, entirely on the Lua config — so it inherently carries the Lua shim
in those same two fields (`"dispatcher": "__lua"`, `"arg": "66"`, an opaque
internal closure index) rather than a real dispatcher name and argument
text. Fabricating a plausible pre-migration shape for this record would
have been dishonest: it never had one. It is recorded here, inserted
verbatim exactly as the live capture produced it, precisely because the
gate's own comparator already excludes `dispatcher`/`arg` from its
structural comparison (the same Lua-shim indirection every other Lua-only
bind's record already carries) — so this one record's shim values cost
nothing at compare time and gain nothing by being disguised.

**Result.** The gate's own positional-difference count dropped from 65 to
exactly 2 — the two documented mouse-field records — immediately after this
insertion and before the forgiveness rule below was added. See the
coverage-limits entry above for the numbers before the forgiveness rule,
and this task's own `14-10-SUMMARY.md` for the full before/after record.

**Cross-reference:** `.hypr-baseline/uncovered.txt`'s `binds.json:mouse`
entry, amended by this same task to record that its named compensating
check (a human physically drag-moving and drag-resizing a window) was
finally run, by whom, and with what result.
