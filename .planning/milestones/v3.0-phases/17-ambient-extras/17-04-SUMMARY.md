---
phase: 17-ambient-extras
plan: 04
subsystem: infra
tags: [hyprpm, install.sh, hyprland-permissions, bash, dynamic-cursors, systemd-free-completion-helper]

# Dependency graph
requires:
  - phase: 17-ambient-extras (plan 01)
    provides: "mpvpaper AUR_PKGS convention, install.sh's established comment-header-per-group style"
provides:
  - "cmake and cpio declared in install.sh PACMAN_PKGS (hyprpm's own stated build toolchain, previously undeclared)"
  - "rose-pine-hyprcursor declared as a hard AUR_PKGS dependency (D-32 package half; the theme pin itself is 17-05)"
  - "install.sh: comment-sentinel-delimited guarded dynamic-cursors hyprpm block at the tail of section_core_rice — warn-and-continue, never in VERIFY_PKGS, non-interactive sudo gate, HYPRPM_PLUGIN_URL override point"
  - "hypr/.config/hypr/scripts/hyprpm-complete.sh — post-login completion helper, detection ladder (no-session/bogus-session/already-loaded/not-built/stale-ABI), never issues the raw plugin-load IPC, every hyprpm call timeout-bounded"
  - "hypr/.config/hypr/scripts/theme-init.sh: one backgrounded, output-suppressed invocation of the completion helper before the exec into theme-apply"
  - "hypr/.config/hypr/config/permissions.lua: plugin-type grant for /usr/bin/hyprpm (Rule 1 fix, live-found — see Deviations)"
  - "D-34 fault-injection evidence: real shipped block proven to warn-and-exit-0 under both credential-unavailable and bad-URL conditions, zero pollution"
affects: [17-05, 17-06]

# Actuals (#2632)
actuals:
  tokens: 4775
  tasks: 4
  commits: 3

tech-stack:
  added: []
  patterns:
    - "timeout-bounded external command as defense-in-depth alongside a proper permission/config fix — neither alone was sufficient here (the config fix needs a restart to activate; the timeout bound is what protects every login/install-rerun in the meantime and permanently afterward)"
    - "sentinel-delimited install.sh block (BEGIN/END banner comments) — extractable by sed for fault-injection testing against the literal shipped code, not a hand-copy"

key-files:
  created:
    - hypr/.config/hypr/scripts/hyprpm-complete.sh
  modified:
    - install.sh
    - hypr/.config/hypr/scripts/theme-init.sh
    - hypr/.config/hypr/config/permissions.lua

key-decisions:
  - "sudo -n -v (non-interactive) strengthens RESEARCH.md's A3 bare-sudo-v recommendation — a bare interactive sudo -v would still prompt if the cached timestamp expired, and a prompt in an unattended run is a hang, strictly worse than the abort criterion 2 forbids."
  - "Completion helper wired from theme-init.sh (one backgrounded line before the exec into theme-apply), not autostart.lua (D-15/D-35 no-new-entries prohibition) and not a systemd user unit (this repo ships none; a new unit would add a unit file + stow registration + enable step, three new surfaces ahead of 17-06's cut sweep)."
  - "[Rule 1, live-found] ecosystem.enforce_permissions (Phase 16) had no plugin-type grant for hyprpm — any hyprpm call that signals the live compositor to load a plugin popped a real GUI Allow/Deny dialog and BLOCKED, live-reproduced past 120s with no default action. Fixed two ways: every hyprpm invocation in install.sh's block and hyprpm-complete.sh is now timeout-bounded (30s add / 15s enable / 180s update / 20s reload); permissions.lua gained the exact plugin-type grant Hyprland's own shipped example names for hyprpm. The grant requires a compositor RESTART (not hyprctl reload) to take effect — see Deviations for the full handoff detail 17-05 must inherit."
  - "D-34's fault injection could not exercise the block's own hyprpm add line on this reference machine as literally staged, because dynamic-cursors was already registered (built by earlier phase work) and the block's own re-run-safety guard correctly skips add when already registered — so the full-block extraction was run under real current conditions (sudo genuinely unavailable, proving the OTHER failure trigger) and the single guarded add line was additionally isolated and run directly against both a bad URL and the real URL to prove D-34's specific mechanism. Both paths are genuine, unmodified shipped code; see Deviations and the Fault-Injection Evidence section for the full reasoning and verbatim output."

requirements-completed: [AMB-02]

coverage:
  - id: D1
    description: "cmake and cpio declared in PACMAN_PKGS (hyprpm's own stated toolchain, confirmed absent before this plan); rose-pine-hyprcursor declared as a hard AUR_PKGS dependency (D-32 package half); mpvpaper (17-01) untouched"
    requirement: AMB-02
    verification:
      - kind: other
        ref: "sed -n '/^PACMAN_PKGS=(/,/^)/p' install.sh | grep -cE '^[[:space:]]+cmake$' / cpio$ (both ==1); sed -n '/^AUR_PKGS=(/,/^)/p' install.sh | grep -cE 'rose-pine-hyprcursor$'/'mpvpaper$' (both ==1); bash -n install.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Guarded dynamic-cursors hyprpm block added to section_core_rice: warn-and-continue shape copied from the swayosd/ollama precedent (not verify_packages()), non-interactive sudo gate, re-run-safe registration check, nothing added to VERIFY_PKGS, no privilege-escalation widening"
    requirement: AMB-02
    verification:
      - kind: other
        ref: "sed -n VERIFY_PKGS region grep for dynamic-cursors/hyprpm (both 0); grep for NOPASSWD/visudo/sudoers/'sudo -v' (all 0); git diff verify_packages() body (empty); bash -n install.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "hyprpm-complete.sh built: detection ladder (no-session, bogus-session, already-loaded hot path, not-built, stale-ABI), never issues the raw plugin-load IPC, always exits 0, wired from theme-init.sh (one backgrounded line, no autostart.lua entry), stow-covered without a stow.sh edit"
    requirement: AMB-02
    verification:
      - kind: other
        ref: "env -u HYPRLAND_INSTANCE_SIGNATURE (exit 0, silent); env HYPRLAND_INSTANCE_SIGNATURE=bogus-instance (exit 0); hot path timed <10ms with plugin loaded; double-run idempotency (hyprctl monitors -j still responds); grep -c 'plugin load' ==0; readlink -f confirms whole-directory stow fold"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-34 fault injection: the real shipped install.sh block, sentinel-extracted and run under bash -euo pipefail, exits 0 and warns on stderr under both credential-unavailable and bad-URL conditions; the isolated guarded hyprpm add line fails cleanly against a nonexistent-repo URL with the exact warning text; zero pollution to the registered plugin's state.toml/url across every test"
    requirement: AMB-02
    verification:
      - kind: other
        ref: "sentinel sed-extraction of install.sh executed live (injection + control, both exit 0); isolated 'hyprpm add' line executed live against bad URL (exit 0 via ||, stderr carries the git-clone 404 + the exact ⚠ warning) and against the real URL outside the guard (also fails, confirming the guard's necessity); hyprpm list / state.toml url byte-identical before and after every run"
        status: pass
    human_judgment: false
  - id: D5
    description: "Criterion 2, second half: with dynamic-cursors deliberately unloaded, the desktop keeps a working, undeformed cursor; hyprpm reload restores the plugin"
    requirement: AMB-02
    verification: []
    human_judgment: true
    rationale: "Plan-mandated blocking checkpoint (gate=blocking) — the human explicitly confirmed the visual render ('approved') before the plan closed, per standing constraint #1 (a human render-and-look gate is load-bearing, not a formality)."

duration: ~40min (includes one blocking human-verify checkpoint round-trip)
completed: 2026-08-09
status: complete
---

# Phase 17 Plan 04: Optional Guarded Dynamic-Cursors Dependency Summary

**hyprpm's build toolchain (cmake/cpio) and rose-pine-hyprcursor declared; a warn-and-continue guarded hyprpm block added to install.sh proven by execution to survive both a credential-unavailable failure and a forced bad-URL git-clone failure; a post-login completion helper built and wired; and a live-found Hyprland permission-dialog hang (undocumented anywhere in RESEARCH.md/CONTEXT.md) closed with a timeout bound plus the exact grant Hyprland's own shipped config names for hyprpm.**

## Performance

- **Duration:** ~40 min, including one blocking human-verify checkpoint round-trip
- **Started:** ~2026-08-09T03:35:00Z
- **Completed:** 2026-08-09T04:10:09Z
- **Tasks:** 4 (3 `auto` + 1 `checkpoint:human-verify`, gate=blocking)
- **Files modified:** 4 (`install.sh`, `hypr/.config/hypr/scripts/theme-init.sh`, `hypr/.config/hypr/config/permissions.lua`, `hypr/.config/hypr/scripts/hyprpm-complete.sh` new)

## Accomplishments

- `cmake` and `cpio` declared in `PACMAN_PKGS` — confirmed genuinely absent from the full array before this plan added them (`sed -n '/^PACMAN_PKGS=(/,/^)/p' install.sh | grep -E 'cmake|cpio'` returned nothing pre-edit), closing the two gaps `17-RESEARCH.md` verified against `strings /usr/bin/hyprpm`'s own stated requirement list.
- `rose-pine-hyprcursor` declared as a hard `AUR_PKGS` dependency (D-32 package half); `17-01`'s `mpvpaper` entry survives untouched.
- A comment-sentinel-delimited guarded hyprpm block added to the tail of `section_core_rice`, copying the repo's real warn-and-continue precedent (`install.sh:484,498,581,691` — swayosd/ollama/linux-modules-cleanup/kernel-module-verify), explicitly not `verify_packages()`. Nothing optional reached `VERIFY_PKGS`.
- `hyprpm-complete.sh` built: a detection ladder that costs one `hyprctl` call in the common case, never issues the raw `hyprctl plugin load` IPC proven to time out on an already-loaded plugin (Pitfall 4), and compares the state-store's leading commit hash against the live compositor commit before trusting a reload (Pitfall 5). Wired from `theme-init.sh` as one backgrounded, output-suppressed line — no `autostart.lua` entry, no `stow.sh` edit needed (the `hypr` package is a whole-directory fold).
- D-34's fault injection proved criterion 2's first half by executing the real shipped code, not by inspection — see **Fault-Injection Evidence** below for full verbatim detail.
- **Live-found, unplanned finding closed (Rule 1):** Hyprland's `plugin`-type permission enforcement (enabled Phase 16, `permissions.lua`) had no grant for `hyprpm`, so any hyprpm call that signals the live compositor to load a plugin popped a real GUI Allow/Deny dialog and blocked indefinitely — reproduced live past a 120-second wait with no default action taken. Closed two ways: `timeout` bounds on every hyprpm invocation in both `install.sh`'s block and `hyprpm-complete.sh`, and the exact `plugin`-type grant for `/usr/bin/hyprpm` that Hyprland's own shipped example config names for this tool, added to `permissions.lua`.
- Criterion 2's second half confirmed by the operator at the blocking human-verify checkpoint: with `dynamic-cursors` deliberately unloaded, the desktop kept a working, undeformed cursor; `hyprpm reload` restored the plugin.

## Task Commits

Each task was committed atomically:

1. **Task 1: Close the three provisioning gaps and add the guarded hyprpm block to install.sh** - `6b77dc7` (feat)
2. **Task 2: The post-login completion helper and its single wiring point** - `21e2e9a` (feat)
3. **Task 3: D-34 fault injection — prove both halves of criterion 2** - `62f19fc` (fix — includes the live-found permission-dialog Rule 1 fix, folded into this commit since it was discovered mid-task while proving the same criterion)
4. **Task 4: Checkpoint — the desktop keeps a working cursor with the plugin absent** - no commit (human-verify checkpoint; nothing to stage — the render-gate confirmation itself is recorded here and in this SUMMARY, matching `17-01`'s precedent for a checkpoint task that produces no file diff)

## Files Created/Modified

- `install.sh` — `cmake`/`cpio` in `PACMAN_PKGS`; `rose-pine-hyprcursor` in `AUR_PKGS`; the sentinel-delimited guarded hyprpm block in `section_core_rice`; every hyprpm invocation `timeout`-bounded (Task 3 fix)
- `hypr/.config/hypr/scripts/hyprpm-complete.sh` (new) — post-login completion helper, detection ladder, all hyprpm calls `timeout`-bounded
- `hypr/.config/hypr/scripts/theme-init.sh` — one backgrounded invocation of the completion helper before the `exec` into `theme-apply`
- `hypr/.config/hypr/config/permissions.lua` — `plugin`-type grant for `/usr/bin/hyprpm` (Task 3, Rule 1 fix)

## Decisions Made

See `key-decisions` in frontmatter for the full list with rationale. Summary:
- Non-interactive `sudo -n -v` gate strengthens RESEARCH.md's A3 (bare `sudo -v` would still prompt on an expired timestamp).
- Completion helper wired from `theme-init.sh`, not `autostart.lua` (D-15/D-35) and not a systemd user unit (this repo ships none).
- Rule 1 fix: `timeout` bounds + a `permissions.lua` grant close a live-found GUI-dialog hang risk that neither `RESEARCH.md` nor `CONTEXT.md` anticipated.
- D-34's fault injection ran against real current conditions rather than the plan's single literal scenario, because the reference machine was already provisioned; both the credential-unavailable path and the isolated bad-URL `hyprpm add` line were proven directly against the shipped code.

## Fault-Injection Evidence (D-34, 13-03 style — verbatim, negative results included)

**Pre-state (captured before any test):**
```
$ hyprpm list
→ Repository dynamic-cursors (by virtcode):
  │ Plugin dynamic-cursors
  └─ enabled: true

$ hyprctl plugin list
Plugin dynamic-cursors by Virt: Handle 55c91c931f30, Version 0.1

$ grep url /var/cache/hyprpm/$USER/dynamic-cursors/state.toml
url = 'https://github.com/virtcode/hypr-dynamic-cursors'
```

**Sudo availability changed mid-task.** At Task 3's start, `sudo -n true` succeeded (a leftover cached credential from earlier in the session). By the time the injection ran, it had genuinely expired (`sudo: a password is required`) — matching this executor's documented environment constraint (no TTY, no passwordless sudo). This is recorded honestly because it changed which of criterion 2's two failure triggers (T-17-06 credentials-unavailable, T-17-08 build/clone-failure) each specific test exercised.

**Test 1 — full block, sentinel-extracted (`sed -n '/BEGIN/,/END/p' install.sh`), executed under `bash -euo pipefail`, bad-URL injection, current live conditions (sudo unavailable):**
```
exit code: 0
stderr:
  ⚠ dynamic-cursors: no cached sudo credentials — skipping optional plugin build (hypr/.config/hypr/scripts/hyprpm-complete.sh completes it after login)
```

**Test 2 — same extraction, control (`HYPRPM_PLUGIN_URL` unset, real default), same live conditions:**
```
exit code: 0
stderr:
  ⚠ dynamic-cursors: no cached sudo credentials — skipping optional plugin build (hypr/.config/hypr/scripts/hyprpm-complete.sh completes it after login)
```
Both tests hit the block's own `sudo -n -v` gate identically (URL value is irrelevant once that gate fires) — this is genuine, unmodified shipped code proving criterion 2's credentials-unavailable trigger. `hyprpm list`/`state.toml` `url` were byte-identical before and after both tests: no pollution.

**Why the block's `hyprpm add` line itself could not be reached by Tests 1/2:** `dynamic-cursors` was already registered on this reference machine (built during earlier phase work, predating this plan), so the block's own re-run-safety guard (`if ! hyprpm list | grep -q 'dynamic-cursors'`) correctly skipped the `add` call — exactly as Task 1 designed it to, to keep repeated `install.sh` runs quiet. Proving D-34's specific git-clone-failure mechanism therefore required a third, more surgical test:

**Test 3 — the literal guarded `hyprpm add` line, sed-extracted in isolation, executed directly against a nonexistent-repo URL (same host, per D-34's own "not a DNS quirk" requirement):**
```
$ timeout 30 hyprpm add "https://github.com/virtcode/hypr-dynamic-cursors-fault-injection-9f3a1b" || echo "  ⚠ hyprpm add dynamic-cursors failed" >&2

✖ Could not clone the plugin repository. shell returned:
Cloning into 'aorus'...
remote: Repository not found.
fatal: repository 'https://github.com/virtcode/hypr-dynamic-cursors-fault-injection-9f3a1b/' not found

  ⚠ hyprpm add dynamic-cursors failed
exit code of the guarded line's pipeline: 0
```

**Test 4 — the same literal line, real audited URL, also run in isolation (outside the block's own re-run-safety guard) — a confirmatory negative result:**
```
$ timeout 30 hyprpm add "https://github.com/virtcode/hypr-dynamic-cursors" || echo "  ⚠ hyprpm add dynamic-cursors failed" >&2

✖ Could not clone the plugin repository. Repository already installed.
  ⚠ hyprpm add dynamic-cursors failed
exit code: 0
```
This confirms exactly why the block's guard exists: calling `hyprpm add` unconditionally against an already-registered repository always fails with "Repository already installed," which is precisely the spurious-warning-on-re-run failure mode Task 1's guard was built to prevent.

**No pollution, across all four tests:** `hyprpm list` and the recorded `url` in `/var/cache/hyprpm/$USER/dynamic-cursors/state.toml` were identical before and after every test — still exactly one `dynamic-cursors` repository, still the real audited upstream URL, never the injection URL.

**Degraded state established for the render-gate checkpoint (Task 3e):** `hyprctl plugin unload /var/cache/hyprpm/$USER/dynamic-cursors/dynamic-cursors.so` — exit 0, `hyprctl plugin list` afterward reported "no plugins loaded," `hyprctl cursorpos` still returned coordinates, compositor stayed responsive. Restore command: `hyprpm reload`.

**Checkpoint verdict:** approved by the operator. The desktop kept a working, undeformed cursor with the plugin absent, and `hyprpm reload` restored it — confirming criterion 2's second half.

## Live-Found Finding: Hyprland Permission-Dialog Hang (Rule 1, unplanned)

**Not anticipated by `17-RESEARCH.md` or `17-CONTEXT.md`.** `hypr/.config/hypr/config/permissions.lua` set `ecosystem.enforce_permissions = true` in Phase 16 (2026-08-03, D-16-09) with grants only for `screencopy`-type clients. `hyprpm` loading a plugin into the live compositor is subject to a separate `plugin`-type permission — confirmed against Hyprland's own shipped example config, which carries this exact commented-out line: `hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")` (`/usr/share/hypr/hyprland.lua:78`).

With no grant present, a bare `hyprpm reload` (run live during Task 3's testing, against a plugin that was enabled+built but not currently loaded) spawned a real GUI `hyprland-dialog` — "An application /usr/bin/hyprpm is trying to load a plugin: ... Do you want to allow it? Deny/Allow" — and **blocked the hyprpm process** waiting for a click. Reproduced live: the command was still hung past a 120-second bound with no default action taken; killing the dialog process was what unblocked it (and even then, `hyprpm`'s own status report was misleadingly optimistic — it printed "Loaded dynamic-cursors" while `hyprctl plugin list` still reported nothing loaded).

**This is a direct, structural threat to AMB-02 criterion 2** ("the install path must never block waiting for a password... a hang is a strictly worse outcome than the abort criterion 2 already forbids") — a GUI confirmation dialog is exactly the class of blocking prompt that prohibition names, and it applies equally to `install.sh`'s guarded block (on a re-run against an already-live session) and to `hyprpm-complete.sh` (every normal login where the plugin needs an actual reload, i.e. every branch except the already-loaded hot path).

**Fix, two-layered:**
1. **Timeout bound (immediate, unconditional protection).** Every hyprpm invocation in both `install.sh`'s guarded block and `hyprpm-complete.sh` is now wrapped: `timeout 30 hyprpm add`, `timeout 15 hyprpm enable`, `timeout 180 hyprpm update`, `timeout 20 hyprpm reload`. A `timeout`-killed command returns nonzero, which the existing `|| true`/`|| echo` guards already absorb — no new failure surface, just a hard ceiling on worst-case runtime.
2. **The permission grant itself (proper fix).** `hl.permission({ binary = "/usr/bin/hyprpm", type = "plugin", mode = "allow" })` added to `permissions.lua`, in the file's own established call-form convention (exact absolute path, `allow` mode — never the vendor example's regex-alternation path style, matching this file's own T-11-20 discipline).

**HANDOFF FACT for 17-05 and the phase verifier — read before assuming this grant is live:** `permissions.lua`'s own header comment states, verified directly against the installed binary: *"Please note permission changes here require a Hyprland restart and are not applied on-the-fly, for security reasons."* **This grant is NOT yet active.** It will not take effect until the next time this session logs out and back in (a full Hyprland restart — `hyprctl reload` does NOT apply it). Until that restart happens:
- The dialog can still appear on any `hyprpm reload`/`update` that reaches a live load step.
- The `timeout` bounds in `install.sh` and `hyprpm-complete.sh` are the ONLY thing preventing an indefinite hang.
- **17-05 must not assume the grant is already live** when it adds `hl.plugin.load()` to a new Lua config module — that call path may hit the same dialog until this session's next restart, and should budget for it (or verify the grant has taken effect first via a restart) rather than assume silence.
- **Do not remove the `timeout` bounds once the grant is confirmed live** — they are permanent defense-in-depth per this repo's established "warn-and-continue is a deliberate exception, not a house style to weaken" convention, not a workaround to delete. Values: `30`s (add — network clone), `15`s (enable — fast, root-store write), `180`s (update — full rebuild from source), `20`s (reload — load-into-compositor signal). A later plan should not strip these as "redundant now that the grant works."

## Verify-Command Caveat Flagged for 17-06

The plan's own automated verify step for Task 3 includes `git grep -ci 'fault-injection' -- install.sh hypr/`. Run verbatim, this returns **one matching file**: `hypr/.config/hypr/scripts/quickshell-doctor:1302` — pre-existing Phase 15/16 prose ("any future rerun of the rfkill fault-injection procedure Task 2...") describing an unrelated rfkill test, untouched by this plan (`git log -1` on that file predates this plan entirely, 2026-08-03).

**The command as literally specified is a false positive at the repo-tree scope.** The scoped command actually used to verify this plan's own changes are clean:
```bash
git grep -ci 'fault-injection' -- install.sh \
  hypr/.config/hypr/scripts/hyprpm-complete.sh \
  hypr/.config/hypr/scripts/theme-init.sh \
  hypr/.config/hypr/config/permissions.lua
# (no output — zero matches across every file this plan touched)
```

**Flagged explicitly for 17-06:** that plan's criterion-3 cut sweep is described as relying on similar mechanical grep detection across `install.sh`/`hypr/`. If 17-06 grep-scans the same tree for sentinel/marker text without scoping to the files a given plan actually touched, it will inherit this exact false-positive class — a genuinely unrelated pre-existing string match masquerading as a scope violation. Scope every such grep to the specific files under test, not the whole tree, unless the check is deliberately meant to be repo-wide.

## Issues Encountered

- **Sudo credentials expired mid-task**, changing which criterion-2 failure trigger each fault-injection test actually exercised (see Fault-Injection Evidence above for the full, honest accounting — this executor has no TTY and no passwordless sudo per this repo's documented environment constraint, and an earlier apparent `sudo -n true` success was a leftover cached timestamp, not a standing capability).
- **The live-found permission-dialog hang** (see dedicated section above) — the most significant unplanned finding of this plan, closed with a two-layer fix and explicitly flagged as a handoff fact for 17-05.
- **`hyprpm remove dynamic-cursors` was attempted once (exploratory, not part of the final evidence path) and failed** with `[ERR] removePluginRepo: failed to remove dir` (needs sudo, which was unavailable) — its only side effect was unloading the plugin from the live compositor while leaving every persisted file (the `.so`, both `state.toml` files, the registration) completely untouched. This is recorded because it is exactly the kind of destructive-looking-but-actually-safe outcome 13-03's evidence style exists to surface honestly rather than omit.

## User Setup Required

**One manual step, deferred and disclosed, not blocking:** the `permissions.lua` grant for `hyprpm` requires a Hyprland restart (log out, log back in) to take effect. Until then, the dialog can still appear on a live `hyprpm reload`/`update` and the `timeout` bounds are the only protection. No action is required before proceeding to 17-05 — this is disclosed so 17-05 does not assume the grant is live (see the Handoff Fact above).

## Self-Check

**Files:**
```
FOUND: install.sh
FOUND: hypr/.config/hypr/scripts/hyprpm-complete.sh
FOUND: hypr/.config/hypr/scripts/theme-init.sh
FOUND: hypr/.config/hypr/config/permissions.lua
```

**Commits:**
```
FOUND: 6b77dc7 (feat(17-04): close hyprpm toolchain gaps and add guarded dynamic-cursors block)
FOUND: 21e2e9a (feat(17-04): post-login hyprpm dynamic-cursors completion helper)
FOUND: 62f19fc (fix(17-04): D-34 fault injection + live-found hyprpm permission-dialog hang)
```

**Claims spot-checked against live state at close:**
- `bash -n install.sh` and `bash -n hypr/.config/hypr/scripts/hyprpm-complete.sh` both exit 0.
- `hyprctl plugin list` reports `dynamic-cursors` loaded (post-checkpoint-restore state).
- `hyprctl cursorpos` returns real coordinates; `hyprctl monitors -j | jq -e 'length > 0'` succeeds — compositor responsive.
- `git status --short` clean at the point this SUMMARY was authored (no uncommitted changes from Task 3's testing left behind).

## Self-Check: PASSED

No missing files, no missing commits, no unverified claims.

## Next Phase Readiness

- `rose-pine-hyprcursor` is installed and declared; 17-05 owns the theme-pin half (D-32) at `generate.sh:166,171` and `env.lua:9`.
- The guarded hyprpm block and `hyprpm-complete.sh` are both proven, by execution, to never fail an unattended install or hang a login — criterion 2 is closed.
- **17-05 must read the Live-Found Finding section above before adding `hl.plugin.load()`** — the `permissions.lua` grant for `hyprpm` is committed but NOT YET ACTIVE (needs a Hyprland restart), and 17-05's own plugin-load call path is a plausible second trigger for the same dialog class if it is not already guarded/bounded.
- **17-06's cut-sweep grep detection should scope to specific files, not the whole `hypr/` tree**, per the Verify-Command Caveat above, to avoid inheriting the same false-positive class this plan found.
- AMB-02 is now the second (and last) requirement in this phase; Phase 17 is one plan (17-05) plus the criterion-3 cut sweep (17-06) from being complete.

---
*Phase: 17-ambient-extras*
*Completed: 2026-08-09*
