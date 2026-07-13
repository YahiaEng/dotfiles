---
phase: 07-super-key-menu
plan: 06
subsystem: ui
tags: [elephant, walker, hyprland, windowrules, zen, ollama, menus, toml]

# Dependency graph
requires:
  - phase: 07-03
    provides: install.sh package declarations (ollama, aichat) for the local-models path
  - phase: 07-05
    provides: root menu with `submenu = "ai-dashboard"` already wired; stow-parity guard in elephant-restart.sh
provides:
  - AI Dashboard submenu (Claude, ChatGPT, Gemini, Perplexity, Claude Code, Local models, AI Workspace)
  - ai-webapp-launch.sh (switch-workspace-then-launch Zen placement shim)
  - ai-workspace.sh (idempotent named-workspace launcher, D-24)
  - ai-local-models.sh (ollama/aichat guards + idempotent aichat config seed, D-22/D-23)
  - windowrules for the kitty AI surfaces (ai-claude-code, ai-local-models)
  - "Live closure of RESEARCH Assumption A1 (MOZ_APP_REMOTINGNAME) AND the deeper title-regex placement failure"
affects: [07-08-cheat-sheet]

tech-stack:
  added: []
  patterns:
    - "Switch-workspace-then-launch: Hyprland places a new window on whichever workspace is ACTIVE at spawn time — the only reliable placement mechanism for a client whose class is non-discriminating and whose title arrives late"
    - "D-09 preserved one level down: a shell shim invoked bare, which itself execs `uwsm app -- <gui>` (same shape as settings.toml's nmtui-launch.sh)"
    - "Fail-closed idempotency: query compositor state before launching; if the query itself fails, launch NOTHING (an empty workspace is recoverable, a doubled one is not)"

key-files:
  created:
    - elephant/.config/elephant/menus/ai-dashboard.toml
    - hypr/.config/hypr/scripts/ai-webapp-launch.sh
    - hypr/.config/hypr/scripts/ai-workspace.sh
    - hypr/.config/hypr/scripts/ai-local-models.sh
  modified:
    - hypr/.config/hypr/config/windowrules.conf
  deleted: []

requirements-completed: [MENU-03]

verification:
  - claim: "menus:ai-dashboard registers live with elephant (registration, not merely TOML-valid)"
    ref: "`elephant listproviders` lists menus:ai-dashboard alongside main/utilities/settings/screenshot"
    status: pass
  - claim: "New TOML is genuinely stowed — live symlink resolves into the real repo"
    ref: "readlink -f ~/.config/elephant/menus/ai-dashboard.toml -> /home/aorus/dotfiles/elephant/.config/elephant/menus/ai-dashboard.toml"
    status: pass
  - claim: "All four scripts pass shellcheck; both TOMLs parse"
    ref: "shellcheck clean on ai-webapp-launch/ai-workspace/ai-local-models; tomllib.load OK on ai-dashboard.toml + main.toml"
    status: pass
  - claim: "RESEARCH Assumption A1 closed live"
    ref: "MOZ_APP_REMOTINGNAME=zen-claude produced class/initialClass STILL 'zen' and the SAME pid as the existing Zen window — env var has no effect (Zen is single-instance)"
    status: pass
  - claim: "Title-regex windowrule placement proven non-functional (deeper than A1)"
    ref: "A/B test with the rule unchanged: window spawned from ws 1 stayed on ws 1; window spawned while name:ai active landed on ai. Rule never re-fires on late title updates."
    status: pass
  - claim: "Named workspace does not collide with Super+1..0 numeric semantics"
    ref: "hyprctl workspaces: name=ai has internal id -1337 (named range), distinct from ids 1..10"
    status: pass
  - claim: "Human checkpoint (AI Dashboard renders, Zen placement, Pitfall-4 regression, D-24 idempotency, numeric workspaces)"
    ref: "Human approved on the live desktop"
    status: pass
    note: "Approval given as a bare 'approved'; the two window counts from step 6 were not itemized back, so idempotency is recorded as human-approved rather than as an operator-observed count."

duration: ~30min (executor run + orchestrator verification and closeout)
completed: 2026-07-13
status: complete
---

# Phase 07 Plan 06: AI Dashboard Summary

## Accomplishments

- **MENU-03 delivered.** The AI Dashboard submenu is live under the root menu (`main.toml` already carried `submenu = "ai-dashboard"` from 07-05) with seven entries across D-21's three launcher classes: four Zen web-apps (Claude/ChatGPT/Gemini/Perplexity), Claude Code in kitty, local models via ollama+aichat in kitty, and the D-24 idempotent AI Workspace.
- **Closed RESEARCH Assumption A1 with a live test**, then found and closed a deeper failure the plan had not anticipated (below).
- **Proved the 07-05 stow-parity guard works on the first new file to hit it** — `ai-dashboard.toml` is a new file in the already-stowed `elephant/` package, exactly the silent-no-op class 07-05 discovered, and the guard self-healed it. `elephant listproviders` shows `menus:ai-dashboard` registered.

## The Headline Finding: Zen Windows Cannot Be Placed by Windowrule At All

D-21 assumed each AI web-app would get its own window class. RESEARCH corrected that to "use a title-regex fallback." **Both are wrong**, and the second one is wrong for a non-obvious reason:

1. **Class is useless.** Zen assigns every window the identical class `zen` regardless of URL.
2. **`MOZ_APP_REMOTINGNAME` does nothing** (A1, closed): setting it produced a window with class/initialClass still `zen` and the *same PID* as the pre-existing Zen window. Root cause: Zen is single-instance — a second `zen-browser` invocation just asks the already-running master process to open a window, and that process never re-reads its environment.
3. **Title-regex also fails, and this is the deeper finding.** Hyprland's `workspace` windowrule is a one-shot dispatch evaluated at window-map time. At that instant Zen's `initialTitle` is the generic `"Zen Browser"` for *every* window — the real page title ("Sign in - Claude — Zen Browser") only arrives after the page loads. The rule never re-fires on later title changes the way continuous properties like opacity/float do. Proven with a clean A/B test in which the rule was present and unchanged in both trials: spawning from workspace 1 left the window on workspace 1; spawning while `name:ai` was active landed it on `ai`.

**The mechanism that works:** Hyprland spawns a new window on whichever workspace is *active* at spawn time. So placement is done by switching to `name:ai` **first**, then launching — in `ai-webapp-launch.sh`, with no windowrule involved. This is also a strictly better Pitfall-4 fix than title-matching: a normal Zen window opened without the workspace-switch preamble is untouched *by construction*, not merely by regex non-match.

Kitty is unaffected — `--class` is set at spawn time and known at map time, so the two kitty AI surfaces keep ordinary class-based windowrules.

## Task Commits

| Commit | What |
|--------|------|
| 7ce4666 | windowrules title-regex discriminator (superseded — the approach it encodes was then disproven) |
| 18a3f72 | windowrules corrected: kitty class rules kept, dead title-regex rules removed, A1 + title-timing finding documented |
| baae4af | ai-workspace.sh (D-24 idempotent) + ai-local-models.sh (D-22/D-23) |
| 1223725 | ai-dashboard.toml + ai-webapp-launch.sh (Task 3) |

## Decisions Made

- **Zen entries route through `ai-webapp-launch.sh`, not a bare `uwsm app -- zen-browser`** — a deliberate deviation from the planned direct command, forced by the placement finding above. D-09 is preserved one level down: the script is invoked bare and itself execs `uwsm app -- zen-browser`, matching settings.toml's existing `nmtui-launch.sh` precedent.
- **`MOZ_APP_REMOTINGNAME` is deliberately NOT set anywhere.** Shipping a proven no-op env var would be cargo-cult and would mislead the next reader.
- **AI Workspace auto-launches only the two kitty surfaces, not the four browser windows.** Opening four Zen windows on every pick is not what "switch to my AI workspace" implies; the web-app entries already land on `name:ai` on their own.
- **`ai-local-models.sh` fails closed and informs.** ollama/aichat are declared in install.sh (07-03) but are not installed on this dev machine, so the script's guards surface "Ollama Not Installed" rather than the plan's anticipated "No Model Installed". Both satisfy D-23's actual requirement (inform, never hang or silently fail).

## Issues Encountered

**The executor agent confabulated a concurrent session and halted before closeout.** Late in a 234k-token / 66-tool-call run it ran `ps aux`, saw `claude --dangerously-skip-permissions` with cwd `/home/aorus/dotfiles`, and concluded a second privileged Claude Code session was racing it — reverting one of its own commits as "injected content" before stopping. **That PID was its own parent process.** The orchestrator verified the process ancestry (`zsh → claude(491965) → fish → kitty → Hyprland`), took two git snapshots six seconds apart to confirm the tree was quiescent, and established that every commit and file attributed to the "other session" was the executor's own work. No second writer existed, nothing was injected, and no work was lost.

Consequence for future plans: **a long-running executor on a live-desktop repo can mistake its own side effects for an adversary.** The orchestrator re-verified every artifact from first principles (diffs, shellcheck, TOML parse, symlink targets, live provider registration) rather than trusting the agent's account, and completed Task 3 + the stow/registration proof directly.

## Next Phase Readiness

- 07-07 (Game Center) adds `game-center.toml` to the same `elephant/` stow package — the parity guard now has two consecutive live proofs.
- 07-08 (cheat-sheet) modifies `windowrules.conf`, which this plan also touched; it must be run *after* this plan's commits (it is — same wave, sequential).
- `ollama`/`aichat` remain uninstalled on this machine. MENU-03's local-models path is correct by construction and guarded, but its `ollama list` parsing and aichat config schema are **not** live-verified against the installed binaries — the one item in this plan not held to the project's "verify against the installed binary" standard. Flagged, not hidden.

---

*Completed: 2026-07-13*
