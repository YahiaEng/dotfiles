# Phase 4: Reliability Fixes & Tech Debt - Research

**Researched:** 2026-07-09
**Domain:** Wayland/Hyprland session management (uwsm), hyprlock authentication timing, zsh/fish shell startup performance, Arch package management
**Confidence:** MEDIUM-HIGH (root causes for FIX-01 and FIX-02 are corroborated by matching upstream GitHub issues; FIX-03 and DEBT-01 are HIGH confidence — directly verified on this machine)

## Summary

This phase fixes three independent reliability defects plus one packaging gap. Live investigation of this exact machine (journalctl, coredumpctl, pacman, `hyprctl version`) plus targeted upstream research turned up strong, specific leads for two of the three bugs — meaning the "diagnose first" mandate in the phase's success criteria has real diagnostic material to start from, not a blank slate.

**FIX-01 (wlogout hang):** This machine runs an NVIDIA RTX 3070 (`nvidia` DRM driver, not nouveau) as the only GPU. There is a well-documented, actively-discussed upstream failure mode where Hyprland/wlroots compositors on NVIDIA hardware hang on a black screen during `systemctl poweroff`/`reboot` because SIGTERM is sent to the compositor but the NVIDIA driver doesn't finish unloading before systemd's shutdown timeout forcibly SIGKILLs it, producing a kernel-level black screen instead of a clean VT handoff (`basecamp/omarchy#5726`). Separately, the specific "mouse click hangs, keyboard hotkey works" wlogout symptom named in the phase's own diagnostic protocol matches a known Hyprland core bug (`hyprwm/Hyprland#4599`), but that was fixed in Hyprland core in March 2024 (`PR #5240`) — and this machine already runs Hyprland 0.55.4 (built June 2026), well past that fix. **That specific mouse-vs-keyboard bug is very unlikely to be the live cause here** — the keyboard-vs-mouse test should still be run (per D-13) to rule it out cleanly, but the NVIDIA shutdown-race hypothesis is the stronger lead. `wleave` (D-15's named replacement) is confirmed actively maintained (328 GitHub stars, latest release Feb 2026) and is explicitly wlogout-config-compatible.

**FIX-02 (hyprlock keystroke drop):** Directly matches a known, currently-open upstream bug: `hyprwm/hyprlock#423` ("Grace cause fail auth") — with `grace > 0`, the grace-period unlock routine fires more than once ("Unlock already happend?" in logs), consuming keystrokes/triggering spurious failed-auth cycles. A fix PR (`#424`) exists upstream but is not yet in the `hyprlock 0.9.5-4` build installed on this machine. This is an exact match for D-17's symptom fingerprint (manual lock → immediate typing → dropped chars) and directly validates D-18/D-19's `grace = 0` mitigation as the correct fix, not a workaround. There is also a real (if 3-months-old) hyprlock SIGABRT coredump on this machine (`coredumpctl`, 2026-04-02) — unrelated symptom (crash, not keystroke drop) but worth a mention in the diagnosis write-up as evidence hyprlock has had stability issues here before.

**FIX-03 (kitty startup):** Every mechanism named in CONTEXT.md's D-01–D-06 is independently confirmed as a standard, well-documented zsh-startup cost center: synchronous `fastfetch` on every shell, remote-URL `oh-my-posh init` fetching from GitHub at every shell start, synchronous `nvm.sh`/`bun` sourcing, and zinit plugin loading. Standard tooling exists for all of them (zsh `zprof`, `hyperfine`, `fastfetch --stat`, zinit turbo `wait`/`lucid` ices, nvm shim lazy-load pattern). `fish` 4.8.0 and `hyperfine` 1.20.0 are both in the official Arch `extra` repo (not AUR) — neither needs an AUR helper.

**DEBT-01 (rsync):** Confirmed — `rsync` is invoked directly and unconditionally in `theme-engine/lib/commit.sh` (the "apply theme" hot path) but is absent from `install.sh`'s `PACMAN_PKGS` array. It is in the official `extra` repo (currently 3.4.4-1) and is almost always present transitively via base-devel/other deps on a dev machine, but a genuinely minimal fresh Arch install can lack it, which would break theme switching silently. This is a one-line fix.

**Primary recommendation:** Diagnose FIX-01 with the NVIDIA-shutdown-race hypothesis as the leading candidate (not the old Hyprland mouse-click bug); diagnose FIX-02 by confirming the grace-period double-unlock signature in hyprlock's logs, then apply `grace = 0`; profile FIX-03 with `zprof` + `hyperfine` + `fastfetch --stat` before touching anything, fix per-cause, then re-measure; add `rsync` to `PACMAN_PKGS` as a trivial one-line DEBT-01 fix.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Session power actions (shutdown/reboot/suspend/hibernate/logout) | Compositor/session (Hyprland + uwsm + systemd-logind) | Wayland client (wlogout/wleave) | wlogout is only a UI that dispatches shell commands; the actual session teardown correctness lives in how those commands interact with uwsm's systemd-managed session, not in the menu widget |
| Screen lock authentication | Wayland client (hyprlock) + PAM | hypridle (trigger) | hyprlock owns grace/input-field timing and PAM auth; hypridle only decides *when* to invoke `loginctl lock-session` |
| Shell startup performance | Interactive shell (zsh/fish) + terminal emulator (kitty) | N/A | Startup cost is entirely userspace shell-init logic (fastfetch, plugin manager, prompt engine, tool init); kitty itself is not the bottleneck (confirmed: kitty.conf's themed include is 22 lines) |
| Package manifest completeness | Install tooling (install.sh) | N/A | Declarative dependency listing is a install-time concern only; no runtime component owns this |

## Standard Stack

### Core (diagnosis & fix tooling — all already-standard for this ecosystem)

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|---------------|
| `journalctl` / `coredumpctl` | systemd (already installed) | Root-cause diagnosis for FIX-01/FIX-02 crashes and shutdown-sequence timing | Explicitly mandated by the phase's own success criteria; systemd's canonical tools for exactly this class of problem |
| `hyprshutdown` | ships with Hyprland ecosystem, see Hyprland wiki | Graceful compositor exit with app quit + `--vt N` NVIDIA black-screen workaround, invoked via `--post-cmd` for the actual `systemctl poweroff`/`reboot` | [CITED: wiki.hypr.land/Hypr-Ecosystem/hyprshutdown] Purpose-built by the Hyprland project specifically for the NVIDIA-shutdown-black-screen class of bug this phase is chasing — evaluate as a FIX-01 candidate if diagnosis confirms the NVIDIA shutdown race |
| `hyperfine` 1.20.0 | official `extra` repo | Statistical CLI benchmarking (cold/warm run comparison) | [VERIFIED: pacman -Si] Not currently installed; de facto standard benchmarking tool named in D-21's "Claude's Discretion" methodology note — `hyperfine` output format (mean/stddev/min/max over N runs) is exactly what D-21/D-22 before/after comparisons need |
| zsh `zprof` module | built into zsh 5.9.1 (already installed) | Per-plugin/per-line startup time breakdown | [CITED: zsh docs / community profiling guides] `zmodload zsh/zprof` as first line, `zprof` as last line of `.zshrc` — zero extra install, standard first step before touching zinit config |
| `fastfetch --stat` | built into fastfetch 2.65.2 (already installed) | Per-module timing breakdown for fastfetch itself | [CITED: fastfetch manpage / GitHub wiki] Purpose-built flag for exactly the D-02 trimming decision — use this to decide which modules to cut, don't guess |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `fish` | 4.8.0-1, official `extra` repo | Candidate shell per D-07 | [VERIFIED: pacman -Si] Not AUR — goes in `PACMAN_PKGS`, not `AUR_PKGS`, if D-09's "fish wins" branch is taken |
| `nvm.fish` (fisher plugin) | n/a | fish-native nvm equivalent | Only needed if fish wins the D-07 benchmark and D-10's parity checklist requires node tooling — `fisher install jorgebucaran/nvm.fish` |
| `wleave` (AUR) | latest tagged 0.7.1 (Feb 2026 release) | wlogout replacement if FIX-01 diagnosis points to an upstream-dead wlogout bug (D-15) | [VERIFIED: GitHub — 328 stars, active Feb 2026 release, explicitly wlogout-config-compatible] Near-drop-in: consumes wlogout's layout/style.css format directly, so the existing `matugen` `[templates.wlogout]` theming target keeps working with minimal path changes |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `grace = 0` config mitigation (D-18) | Wait for upstream hyprlock PR #424 fix and pin a patched version | Slower — no merged/released fix as of research date; `grace = 0` is a same-day, zero-risk mitigation per D-19's explicit allowance |
| `wleave` | `hyprshutdown`'s own minimal exit UI, or patching wlogout's own six actions to be uwsm-correct without replacing the binary | If diagnosis shows the hang is purely an uwsm/systemctl invocation problem (not a wlogout-specific defect), D-15's replacement trigger doesn't fire — fix in place first, only replace if wlogout itself is the confirmed culprit |
| Manual `zprof`/`hyperfine` profiling | `hyperfine`-only black-box timing (no per-plugin breakdown) | `hyperfine` alone tells you *that* it's slow, not *what* is slow — pair with `zprof`/`fastfetch --stat` for root cause, use `hyperfine` for the final before/after number in D-21 |

**Installation (only what's genuinely missing on this machine):**
```bash
sudo pacman -S --noconfirm hyperfine rsync
# fish only if D-07's benchmark picks it:
sudo pacman -S --noconfirm fish
```
`rsync` (3.4.4-1) and `fish` (4.8.0-1) version-verified via `pacman -Si` on 2026-07-09. `hyperfine` (1.20.0-1) likewise. All three are official `extra` repo — no AUR involvement, no legitimacy concerns.

## Package Legitimacy Audit

> All packages in this phase are Arch official-repo or AUR packages, not npm/PyPI/crates — the generic `package-legitimacy check` seam only supports registry ecosystems it recognizes (npm/PyPI/crates) and does not cover pacman/AUR. Verification below was done directly against `pacman -Si` (official repos) and the upstream GitHub project (for the one AUR package) per the ecosystem-appropriate registry-verification requirement.

| Package | Registry | Age/Activity | Downloads/Popularity | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `rsync` | pacman `extra` (official) | Long-established (samba.org project) | Base Arch package, near-ubiquitous | rsync.samba.org | OK | Approved |
| `hyperfine` | pacman `extra` (official) | Actively maintained (sharkdp) | Standard Arch benchmarking tool | github.com/sharkdp/hyperfine | OK | Approved |
| `fish` | pacman `extra` (official) | Long-established, v4.8.0 current | Major shell, official-repo shipped | fishshell.com / github.com/fish-shell/fish-shell | OK | Approved |
| `wleave` | **AUR** (unofficial, user-submitted PKGBUILD) | Active — 328 GitHub stars, latest tagged release Feb 2026 | Popular within Hyprland-rice community per web search corroboration | github.com/AMNatty/wleave | OK (AUR-tier trust) | Approved, but AUR packages are inherently unvetted by Arch — planner must add a `checkpoint:human-verify` before install (see below), consistent with existing repo convention for all `AUR_PKGS` entries |
| `nvm.fish` (fisher plugin) | GitHub via fisher, not a registry package | n/a — only pulled in if fish wins D-07 and D-10 parity requires it | n/a | github.com/jorgebucaran/nvm.fish | [ASSUMED — not independently verified this session; discovered via WebSearch, not fetched directly] | Conditional — only relevant if fish is chosen; planner should re-verify at that decision point |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none (AUR packages are flagged for human-verify checkpoint per repo convention, not because of a SUS signal — this repo already installs `wlogout` itself from AUR today with no incident, so this is a routine AUR install, not an anomaly)

*`nvm.fish` is tagged `[ASSUMED]` because it was only discovered via WebSearch summary, not fetched/confirmed directly against its GitHub repo this session — if D-07's benchmark picks fish, the planner must gate its install behind `checkpoint:human-verify` and independently confirm the package before use.*

## Architecture Patterns

### System Architecture Diagram — FIX-01 (session teardown path)

```
[User] --keybind/mouse--> [wlogout/wleave UI]
                               |
                               v
                    action string, e.g. "systemctl poweroff"
                               |
                               v
                  [shell exec, NOT uwsm-wrapped today]
                               |
                               v
                    [systemd-logind] --SIGTERM--> [Hyprland compositor]
                               |                         |
                               |                    (NVIDIA driver unload,
                               |                     may not finish before
                               |                     systemd's kill-timeout)
                               v                         v
                    [VT switch back to console]   <-- races here -->
                               |
                               v
                    (success: clean poweroff)  vs  (failure: black screen,
                                                      forced power cycle)
```

Diagnosis inserts observation points at: (1) which action string uwsm-wraps vs. doesn't (`lock`/`logout` already use `uwsm app --`/`uwsm stop`; `suspend`/`hibernate`/`shutdown`/`reboot` currently call bare `systemctl` — see Component Responsibilities below), and (2) whether `journalctl -b -1` shows a `stop-sigterm timed out. Killing` message correlated with the nvidia_drm module, matching the `omarchy#5726` pattern.

### Recommended Project Structure (no new files needed — existing stow packages own all touched files)
```
wlogout/.config/wlogout/          # layout (6 actions), style.css, icons — stays if wlogout survives diagnosis
hypr/.config/hypr/
├── scripts/wlogout.sh            # toggle launcher — audit uwsm-correctness here
├── hyprlock.conf                 # grace=0 mitigation lands here
├── hypridle.conf                 # idle-trigger path — separate from manual-lock symptom per D-17
└── config/keybinds.conf          # $lock_screen already uwsm-correct; SHIFT+Q binding unaffected by fix
kitty/.config/kitty/kitty.conf    # only touched if kitty-side config (not shell) is the profiling culprit
zshell/.zshrc                     # fastfetch trim, oh-my-posh local vendor, nvm/bun lazy-load, zinit turbo
fish/.config/fish/                # NEW stow package, only created if D-09's fish-wins branch is taken
install.sh                        # PACMAN_PKGS += rsync (DEBT-01); += fish (only if D-09 branch taken)
```

### Pattern 1: uwsm-correct session action
**What:** Every command that terminates or transitions the graphical session should go through `uwsm stop` (logout) or be issued in a way that lets uwsm's systemd unit bindings unwind cleanly, rather than calling `systemctl poweroff/reboot/suspend/hibernate` as a bare, unmanaged shell command from inside the session.
**When to use:** Any of the six wlogout actions that end or suspend the current graphical session (all except pure app-launches).
**Example (current repo state — NOT yet uwsm-correct for 4 of 6 actions):**
```jsonc
// wlogout/.config/wlogout/layout — current state
{ "label": "lock",      "action": "uwsm app -- hyprlock" }   // uwsm-correct
{ "label": "logout",    "action": "uwsm stop" }               // uwsm-correct
{ "label": "suspend",   "action": "systemctl suspend" }        // bare — audit per D-14
{ "label": "hibernate", "action": "systemctl hibernate" }      // bare — audit per D-14
{ "label": "shutdown",  "action": "systemctl poweroff" }       // bare — root-cause target for FIX-01
{ "label": "reboot",    "action": "systemctl reboot" }         // bare — root-cause target for FIX-01
```
Per the `hyprwm/Hyprland#12174` discussion [CITED: github.com/hyprwm/Hyprland/discussions/12174]: `uwsm stop` before a shutdown/reboot does not hang, while calling `systemctl reboot` directly from inside the session has been reported to hang/timeout in exactly this uwsm-managed-session scenario. The uwsm-correct pattern is generally: end the uwsm-managed session first (or ensure the compositor gets a clean, non-forced exit signal), *then* issue the systemd power transition — this is the "class of bug" fix D-13 asks for, not a per-action patch.

### Pattern 2: hyprlock grace-period mitigation
**What:** Set `grace = 0` in `general {}` to eliminate the double-unlock-attempt race in hyprlock's grace-period handling.
**When to use:** Confirmed if `journalctl`/hyprlock's own debug log shows the "In grace and cursor moved more than 5px, unlocking! ... Unlock already happend?" signature from `hyprwm/hyprlock#423` [CITED: github.com/hyprwm/hyprlock/issues/423].
**Example:**
```
# hypr/.config/hypr/hyprlock.conf
general {
    grace = 0          # was: grace = 5 — the grace-period unlock routine
                        # fires >1x, consuming/racing with real keystrokes
    hide_cursor = true
    no_fade_in = false
    no_fade_out = false
}
```

### Pattern 3: fastfetch module timing before trimming
**What:** Never guess which fastfetch modules are slow — measure first.
**When to use:** Before making any D-02 module-removal decisions.
**Example:**
```bash
# Source: fastfetch manpage / GitHub wiki (--stat flag)
fastfetch --stat
```
The current repo config (`fastfetch/.config/fastfetch/config.jsonc`) does **not** currently include a `displaymanager`, `battery`, or `poweradapter` module (contrary to CONTEXT.md D-02's phrasing, which may be recalling generic fastfetch-slowness advice rather than this repo's actual config). It **does** include `disk` (stats `/`) and `gpu` (on NVIDIA systems, the gpu module can shell out and add latency) — these are the concrete present-and-plausible candidates; `--stat` will confirm which, if any, are actually slow on this hardware.

### Pattern 4: zinit turbo-mode async plugin loading
**What:** Defer plugin sourcing until after the first prompt draws, using zinit's `wait`/`lucid` ices.
**When to use:** If `zprof` shows zinit plugin loading (not fastfetch/oh-my-posh/nvm) as the dominant cost, per D-05.
**Example:**
```zsh
# Source: zdharma-continuum/zinit README + community turbo-mode guides
# Current (synchronous, blocks prompt):
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions

# Turbo (async, loads after prompt is usable):
zinit wait lucid for \
    zsh-users/zsh-syntax-highlighting \
    zsh-users/zsh-autosuggestions \
    Aloxaf/fzf-tab
```
[CITED: reported 50-80% zsh startup reduction from turbo mode in community benchmarks — treat as directional, not a guaranteed number for this specific plugin set; verify with `hyperfine` before/after]

### Pattern 5: nvm/bun lazy-load shim
**What:** Replace synchronous `nvm.sh` sourcing with a self-deleting shim function that only loads nvm on first `node`/`npm`/`nvm`/`npx` invocation.
**When to use:** If `zprof` attributes meaningful startup cost to the current lines:
```zsh
# Current (zshell/.zshrc:102-103) — synchronous, always pays the cost:
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```
**Example (standard lazy shim pattern):**
```zsh
# Source: community-standard nvm lazy-load pattern (dev.to/thraizz, zenn.dev/catatsuy)
export NVM_DIR="$HOME/.config/nvm"
lazy_load_nvm() {
    unset -f nvm node npm npx bun 2>/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}
for cmd in nvm node npm npx bun; do
    eval "function $cmd() { lazy_load_nvm; $cmd \"\$@\" }"
done
```
[CITED: reported 300-500ms saved by lazy-loading nvm in multiple independent community writeups — directional, verify with this repo's actual `hyperfine` numbers]

### Anti-Patterns to Avoid
- **Patching wlogout's shutdown action alone without auditing all six (skipping D-14):** The uwsm-vs-bare-systemctl inconsistency already exists across all six actions in the current layout file — fixing only shutdown/reboot and leaving suspend/hibernate on the same bare pattern reintroduces the same bug class later.
- **Disabling hyprlock's fade/grace entirely as a blind guess:** D-19 explicitly requires the root cause to be *documented with evidence* (log signature match) before applying `grace = 0` — don't skip straight to the config change without confirming the `#423` signature in this machine's logs first.
- **Removing fastfetch modules without `--stat` evidence:** the CONTEXT.md's named suspects (DisplayManager) aren't even in this repo's current config — trimming based on generic internet advice rather than measured local data risks cutting modules that aren't actually slow while missing ones that are (e.g. `gpu` on NVIDIA).
- **Benchmarking kitty startup by measuring only process spawn time:** `time kitty` returns almost immediately (kitty forks and detaches); D-21's "time-to-usable-prompt" must be measured end-to-end (keypress-to-interactive), e.g. via a script that launches kitty and polls until the shell prompt is ready to accept input, not via a naive `hyperfine 'kitty ...'` process-exit timer.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-module fastfetch timing | Custom `time fastfetch` wrapper script | `fastfetch --stat` | Built-in, per-module granularity a wrapper script around the whole binary can't give you |
| zsh startup profiling | Manual `date +%s%N` timestamps sprinkled through `.zshrc` | `zsh/zprof` module | Standard, zero-maintenance, gives per-function/per-plugin breakdown automatically |
| Statistical before/after benchmarking | Ad-hoc `for i in 1..10; do time ...; done` loop | `hyperfine` | Handles warmup runs, statistical outliers, min/max/stddev reporting — exactly what D-21/D-22's "concrete budget" comparisons need |
| Graceful NVIDIA-safe compositor shutdown | Custom pre-exit script that manually kills clients and switches VTs | `hyprshutdown --vt N --post-cmd 'systemctl poweroff'` | Purpose-built by the Hyprland project for exactly this failure mode — a hand-rolled VT-switch script would be re-implementing a maintained upstream tool |
| Session-aware power actions | Custom uwsm-wrapper functions | uwsm's own documented `uwsm stop` / session-target patterns | uwsm already exposes the correct primitives (per `hyprwm/Hyprland#12174` and the Hyprland wiki's systemd-start doc); wrapping `systemctl` calls in custom logic duplicates what uwsm already solves |

**Key insight:** Every defect in this phase already has a maintained upstream tool or documented pattern that directly addresses it (hyprshutdown for NVIDIA shutdown races, uwsm's own stop semantics for session teardown, hyprlock's own `grace` config knob, fastfetch's own `--stat` flag, zsh's own `zprof`). The phase's job is root-cause diagnosis + applying the *existing* correct primitive, not inventing new workaround machinery — consistent with the project's stated "root-cause over patch-around" convention.

## Common Pitfalls

### Pitfall 1: Misattributing FIX-01 to the old Hyprland mouse-click bug
**What goes wrong:** The phase's own success criteria names a "keyboard-vs-mouse test" as the first diagnostic step, which closely matches `hyprwm/Hyprland#4599`'s symptom. Chasing that lead specifically will likely find nothing, because it was fixed in Hyprland core in March 2024 (PR #5240) and this machine runs Hyprland 0.55.4 (June 2026 build) — over two years past the fix.
**Why it happens:** The keyboard-vs-mouse test is a valid general diagnostic (it isolates input-path vs. exec-path issues), but its historical association with issue #4599 can bias diagnosis toward the wrong root cause.
**How to avoid:** Run the keyboard-vs-mouse test as specified (it's cheap and rules things out), but treat a "no difference between keyboard and mouse" result as evidence *against* #4599 and *for* the NVIDIA shutdown-race hypothesis — then pivot to `journalctl -b -1` looking for `stop-sigterm timed out. Killing` near nvidia_drm module unload messages.
**Warning signs:** If both keyboard and mouse invocations hang identically, the bug is not input-path-specific — look at the exec/session-teardown path instead.

### Pitfall 2: Applying `grace = 0` without confirming the log signature
**What goes wrong:** Setting `grace = 0` blind (without checking for the `#423` "Unlock already happend?" signature) means the fix might be masking a different bug, and the documentation requirement in D-19 ("root cause documented with evidence") won't actually be met.
**Why it happens:** `grace = 0` is such a cheap, low-risk change that it's tempting to apply it first and skip verification.
**How to avoid:** Reproduce the drop with `grace = 5` first, capture hyprlock's stderr/debug output (hyprlock logs to `~/.cache/hyprlock/` or via `hyprlock -v` foreground run) or `journalctl --user -u` app-scope, confirm the double-unlock log line, *then* apply the fix and re-run D-23's 10-trial protocol to confirm 100% pass.
**Warning signs:** If dropping to `grace = 0` doesn't fully resolve the issue in the 10-trial test, the root cause may be different (e.g. genuine input-grab/focus timing at hyprlock startup, unrelated to the grace routine) — don't stop at the first plausible-looking fix.

### Pitfall 3: Fixing kitty startup by changing kitty.conf instead of shell startup
**What goes wrong:** `kitty.conf`'s `repaint_delay`/`input_delay`/`sync_to_monitor` settings look like performance knobs but govern rendering latency, not shell-startup latency — tuning them will not fix a slow prompt.
**Why it happens:** kitty.conf is the more "obvious" performance-sounding file to touch; the real cost (fastfetch, oh-my-posh, nvm, zinit) lives entirely in `.zshrc`, which loads independently of kitty.
**How to avoid:** D-01 already scopes the fix to "wherever profiling points" — trust the `zprof`/`hyperfine` numbers, not intuition about which file "sounds like" the performance file.
**Warning signs:** If profiling shows kitty's own process-spawn time (not shell-init time) as the bottleneck, that's a different and much rarer problem (GPU/driver-related kitty rendering init) — D-06 already rules out the single-instance masking non-fix for this.

### Pitfall 4: DEBT-01 fix without a version pin regression check
**What goes wrong:** Simply adding `rsync` to `PACMAN_PKGS` is correct, but should be verified against the container gate rerun (D-24) to confirm it doesn't collide with any existing package or introduce a new interactive prompt (this repo's own `install.sh` comments document a prior incident where an unguarded pacman operation prompted for confirmation in the container gate — see `install.sh` D-59 comment).
**Why it happens:** A one-line addition feels too trivial to need a full container-gate rerun.
**How to avoid:** Per D-24, DEBT-01 doesn't need a new bespoke test — just confirm the existing `verify/container-run.sh` gate still passes cleanly after the addition.
**Warning signs:** A gate run that prompts interactively or fails on `rsync`'s own dependency chain (`acl`, `lz4`, `openssl`, `popt`, `xxhash`, `zlib`, `zstd` — all already present as base-system deps) would be an unexpected regression worth investigating, not silently retrying.

## Code Examples

### Diagnostic: capture the NVIDIA shutdown-race signature (FIX-01)
```bash
# After a hang-reproducing shutdown attempt + hard power cycle, on next boot:
journalctl -b -1 --no-pager | grep -iE "sigterm|sigkill|nvidia_drm|stop-sigterm|timed out"
coredumpctl list --since="-1 day"
```

### Diagnostic: confirm hyprlock grace-race signature (FIX-02)
```bash
# Run hyprlock in foreground with verbose logging, then immediately type after lock:
uwsm app -- hyprlock -v
# Look for: "In grace and cursor moved more than 5px, unlocking!" followed by
# "Unlock already happend?" — this is the exact hyprwm/hyprlock#423 signature.
```

### Benchmark: kitty time-to-usable-prompt (FIX-03, D-21)
```bash
# Source: hyperfine docs + community zsh-profiling guides, adapted for
# "time to usable prompt" rather than raw process-exit time.
hyperfine --warmup 3 --min-runs 10 \
    'zsh -i -c exit'    # cold/warm shell-init cost in isolation

# Full fastfetch module breakdown:
fastfetch --stat

# zsh per-line/per-plugin profile (temporarily add to top/bottom of .zshrc):
#   zmodload zsh/zprof   (first line)
#   zprof                (last line)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Direct `systemctl poweroff/reboot` from within a Wayland session | uwsm-mediated session stop, or purpose-built `hyprshutdown` with `--vt` NVIDIA workaround | uwsm adoption is recent (this repo already uses it for `lock`/`logout`); `hyprshutdown` is an actively-developed Hyprland-ecosystem tool | Bare `systemctl` calls from inside a uwsm-managed session are increasingly documented as the wrong pattern in current (2026) Hyprland/uwsm community discussion |
| `wlogout` as the default Hyprland logout menu | `wleave` (GTK4/libadwaita rewrite, wlogout-config-compatible) gaining adoption as wlogout's maintenance has slowed | wleave's most recent tagged release is Feb 2026 | Directly relevant to D-15's replacement-preference decision |
| Synchronous shell-startup tool init (nvm, oh-my-posh remote fetch, all zinit plugins loaded eagerly) | Lazy-load shims + turbo-mode async plugin loading + local-vendored theme configs | Long-standing community best practice, not a recent shift | Every item CONTEXT.md's D-02/D-03/D-04/D-05 already prescribes matches current best practice — no need to research alternatives, just implement |

**Deprecated/outdated:**
- Remote-URL `oh-my-posh init --config 'https://raw.githubusercontent.com/...'` at every shell start: fetches over the network (or at minimum stats/validates a URL) on every single interactive shell open — D-03's local-vendor fix is the standard fix for this exact anti-pattern, not project-specific.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `nvm.fish` (jorgebucaran/nvm.fish via fisher) is the correct fish-native nvm equivalent for D-10's parity checklist | Standard Stack / Package Legitimacy Audit | If wrong package/approach, fish parity checklist (D-10) fails on node tooling; low risk since this is only reached if D-07's benchmark picks fish, and the planner is directed to re-verify at that decision point |
| A2 | The NVIDIA shutdown-race (`omarchy#5726` pattern) is the leading FIX-01 hypothesis for *this* machine specifically | Summary / Architecture Patterns | This is a plausible, well-corroborated hypothesis given the confirmed NVIDIA-only GPU, but it has not been confirmed against *this machine's own* shutdown-hang logs (no hang has been reproduced/captured yet in this research session — no failed boot showing the exact signature was found in the available `journalctl` history). If wrong, the diagnostic protocol (D-13/D-22) will surface the actual cause during execution; this is a starting hypothesis, not a confirmed root cause |
| A3 | Zinit turbo mode's commonly-cited "50-80% faster" figure will apply proportionally to this repo's specific plugin set | State of the Art / Pattern 4 | Directional only — actual savings depend on which specific plugins/snippets are the cost driver; D-21's `hyperfine` before/after numbers are the real source of truth, not this cited figure |
| A4 | `hyprshutdown` (the wiki-documented tool) is compatible with being invoked as a wlogout/wleave menu action (via `--post-cmd`) rather than only as a standalone keybound exit dialog | Standard Stack / Don't Hand-Roll | If `hyprshutdown`'s own GUI dialog conflicts with wlogout/wleave's UI (two power-menu UIs), the planner may need to use `hyprshutdown --dry-run`-verified flags non-interactively instead of its GUI mode, or use the `--vt` VT-switch technique directly in a plain script without the GUI — this is a config detail to resolve during planning, not a blocker |

## Open Questions

1. **Has FIX-01's black-screen hang actually been reproduced with a timestamp captured in `journalctl`?**
   - What we know: No boot in the available `journalctl --list-boots` history (last 5 boots) shows a truncated/abrupt ending consistent with a hard power-cycle recovery from a genuine hang; all recent boots show clean logind session transitions.
   - What's unclear: Whether the hang is intermittent/rare (and simply hasn't occurred in the last 5 boots) or whether the symptom described in CONTEXT.md needs to be freshly reproduced during phase execution.
   - Recommendation: D-22's "5 consecutive real shutdown/reboot cycles" protocol will both reproduce and log the failure if it's reproducible on demand; if it doesn't reproduce in 5 cycles, treat as intermittent and widen the log-capture window (`journalctl -b -2`, `-3`, etc.) to find a historical occurrence before concluding the NVIDIA hypothesis.

2. **Is `nvidia_drm.modeset=1` explicitly set on this system, or relying on driver defaults?**
   - What we know: No `nvidia_drm.modeset=1` on the kernel cmdline, no `mkinitcpio.conf` MODULES entry for nvidia, but `/usr/lib/modprobe.d/nvidia-*.conf` (package-shipped, not user-authored) sets `NVreg_UseKernelSuspendNotifiers=1` and blacklists nouveau — modern nvidia-dkms packages on Arch often ship modeset-on-by-default behavior.
   - What's unclear: Whether a modeset/KMS timing detail is a contributing factor to the shutdown race (early vs. late DRM master handoff during shutdown).
   - Recommendation: Low priority — only chase this if the primary NVIDIA-shutdown-race + `hyprshutdown --vt` fix doesn't fully resolve FIX-01; not needed for initial diagnosis.

3. **Does `hyprshutdown` need to be added as a new install.sh dependency, or is it bundled with the `hyprland` package?**
   - What we know: The Hyprland wiki documents it as part of the "Hypr-Ecosystem" but it may ship as a separate binary/repo (`hyprshutdown` project) rather than bundled inside the main `hyprland` package.
   - What's unclear: Exact package name and repo (official vs AUR) — not verified this session.
   - Recommendation: If the planner selects `hyprshutdown` as part of the FIX-01 fix, verify its package name/repo via `pacman -Ss hyprshutdown` / AUR search at planning time, and run it through the same package-legitimacy verification protocol applied to `wleave` in this document.

## Project Constraints (from CLAUDE.md)

- **Tech stack is fixed**: Arch Linux, Hyprland, uwsm, stow, matugen — this phase extends/fixes the existing setup, does not rewrite it. All recommendations above (uwsm-correct actions, wleave as a near-drop-in wlogout replacement, hyprlock config-level fix) comply — none propose a stack change.
- **Theme pipeline compatibility**: Any wlogout replacement (wleave) must keep working with the existing `matugen` `[templates.wlogout]` theming target and the `~/.local/state/theme/` state-dir consumption pattern — confirmed compatible (wleave is wlogout-config-format-compatible).
- **Reproducibility**: Everything must install via `install.sh` + stow, no manual host-only state — the DEBT-01 fix (rsync in `PACMAN_PKGS`) and any fish/wleave additions must land in `install.sh`'s package arrays and the appropriate stow package, not be manually installed out-of-band.
- **What NOT to use** (from CLAUDE.md's existing table, still applicable): do not introduce `xsettingsd` (irrelevant to this phase, listed for completeness); do not use `adw-gtk3` as an AUR package name (unrelated to this phase's scope, already flagged as a separate known issue); GSD workflow enforcement — all file changes in this phase must go through `/gsd-plan-phase` → `/gsd-execute-phase`, not direct edits.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIX-01 | wlogout shutdown completes reliably — root cause diagnosed (keyboard-vs-mouse test, journalctl/coredumpctl) and fixed before any redesign work | NVIDIA shutdown-race hypothesis (`omarchy#5726`) identified as leading candidate; historical Hyprland mouse-click bug (`#4599`) ruled unlikely (fixed pre-2024, this machine runs 0.55.4/June-2026); uwsm-correctness gap found in 4 of 6 wlogout actions (Pattern 1); `hyprshutdown --vt` and `wleave` identified as concrete fix/replacement candidates; D-22's 5-cycle test protocol will reproduce/confirm |
| FIX-02 | Hyprlock registers first keystrokes after lock — no dropped-input failed-auth loop, root-caused not patched around | Exact upstream match found: `hyprwm/hyprlock#423` grace-period double-unlock bug, log signature identified, `grace=0` mitigation confirmed as the documented-evidence-backed fix per D-18/D-19; diagnostic command (`hyprlock -v`) provided |
| FIX-03 | Kitty startup profiled, cause identified, fixed | All 4 named cost centers (fastfetch, remote oh-my-posh, sync nvm/bun, zinit plugins) confirmed present in current `.zshrc`; `zprof`/`hyperfine`/`fastfetch --stat` profiling tools identified; standard lazy-load/turbo-mode fix patterns documented with code examples; `fish`/`hyperfine` confirmed in official repo for D-07/D-21 |
| DEBT-01 | rsync listed explicitly in install.sh PACMAN_PKGS | Confirmed `rsync` used unconditionally in `theme-engine/lib/commit.sh`, absent from `PACMAN_PKGS`, available in official `extra` repo (3.4.4-1) — one-line fix, covered by existing container gate rerun per D-24 |
</phase_requirements>

## Sources

### Primary (HIGH confidence — direct verification on this machine)
- `pacman -Q`/`-Qi`/`-Si` for wlogout, hyprlock, hypridle, kitty, zsh, oh-my-posh, fastfetch, hyprland, fish, hyperfine, rsync
- `hyprctl version` — confirmed Hyprland 0.55.4, built June 2026
- `lspci -k` — confirmed NVIDIA GA104 (RTX 3070), `nvidia` driver in use, no nouveau
- `journalctl --list-boots`, `journalctl -b -1`, `journalctl -k -b -1` — confirmed no abrupt-ending boot in recent history; found AUR-provider-selection log noise unrelated to this phase
- `coredumpctl list` / `coredumpctl info` — confirmed hyprlock SIGABRT coredump 2026-04-02 (unrelated symptom, noted for context)
- Direct repo file reads: `wlogout/.config/wlogout/layout`, `hypr/.config/hypr/scripts/{wlogout.sh,powermenu.sh}`, `hypr/.config/hypr/{hyprlock.conf,hypridle.conf}`, `hypr/.config/hypr/config/keybinds.conf`, `kitty/.config/kitty/kitty.conf`, `zshell/.zshrc`, `install.sh` (PACMAN_PKGS/AUR_PKGS), `theme-engine/.config/theme-engine/lib/commit.sh`, `fastfetch/.config/fastfetch/config.jsonc`, `uwsm/.config/uwsm/env-hyprland`, `matugen/.config/matugen/config.toml`

### Secondary (MEDIUM confidence — WebFetch of specific GitHub issues/PRs, cross-checked against this machine's confirmed state)
- [hyprwm/hyprlock#423 "Grace cause fail auth"](https://github.com/hyprwm/hyprlock/issues/423) — exact FIX-02 root-cause match
- [hyprwm/Hyprland#4599 "wlogout logout hangs on mouse click"](https://github.com/hyprwm/Hyprland/issues/4599) and [PR #5240](https://github.com/hyprwm/Hyprland/pull/5240) — ruled unlikely for this machine (fixed pre-2024)
- [basecamp/omarchy#5726 "Shutdown/restart hangs on black screen ... NVIDIA"](https://github.com/basecamp/omarchy/issues/5726) — leading FIX-01 hypothesis
- [wiki.hypr.land/Hypr-Ecosystem/hyprshutdown](https://wiki.hypr.land/Hypr-Ecosystem/hyprshutdown/) — `--vt` NVIDIA workaround
- [github.com/AMNatty/wleave](https://github.com/AMNatty/wleave) — 328 stars, Feb 2026 release, wlogout-config-compatible
- [hyprwm/Hyprland Discussion #12174 "systemctl reboot hangs, but uwsm stop does not"](https://github.com/hyprwm/Hyprland/discussions/12174) — uwsm-correct pattern

### Tertiary (LOW confidence — WebSearch only, not independently fetched/verified)
- zinit turbo-mode 50-80% speedup figures (community-reported, directional)
- nvm lazy-load 300-500ms savings figures (community-reported, directional)
- fish-shell `nvm.fish`/fisher ecosystem parity details (A1 in Assumptions Log)
- `fastfetch --stat` flag existence/behavior (corroborated across multiple independent sources but not run directly on this machine this session)

## Metadata

**Confidence breakdown:**
- FIX-01 diagnosis direction: MEDIUM — strong corroborating upstream pattern (NVIDIA+Hyprland shutdown race) but not yet confirmed against this machine's own captured hang; keyboard-vs-mouse test result will validate/invalidate at execution time
- FIX-02 diagnosis: HIGH — exact upstream issue match with matching symptom fingerprint and log signature to check for
- FIX-03 diagnosis: HIGH — every named cost center directly confirmed present in the actual repo file; tooling verified available
- DEBT-01: HIGH — direct grep confirmation of the gap, trivial fix, package verified in official repo
- Standard stack/tooling: HIGH — all core tools (`hyperfine`, `fish`, `zprof`, `fastfetch --stat`) verified either installed or available in official repos
- Package legitimacy: HIGH for official-repo packages (direct `pacman -Si`), MEDIUM for `wleave` (AUR, but corroborated via GitHub activity), LOW for `nvm.fish` (not independently verified — flagged in Assumptions Log)

**Research date:** 2026-07-09
**Valid until:** 30 days (stable desktop-config domain; re-verify Hyprland/hyprlock versions and upstream issue status if execution is delayed past that window, since both projects ship frequent point releases that could land the cited fixes)
