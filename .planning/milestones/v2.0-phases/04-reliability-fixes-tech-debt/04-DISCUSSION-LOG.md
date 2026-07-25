# Phase 4: Reliability Fixes & Tech Debt - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-09
**Phase:** 4-Reliability Fixes & Tech Debt
**Areas discussed:** Kitty fix scope boundary, wlogout fix policy, Hyprlock behavior trade-offs, Verification depth, Fish migration mechanics, Shell benchmark decision rule, Replacement preference order, Diagnosis documentation home

---

## Kitty fix scope boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Follow the profile | Fix wherever profiling points — kitty config, zshrc, or both | ✓ |
| Kitty-only | Only touch kitty-level issues; defer .zshrc changes | |
| Zsh overhaul | Broader shell-startup cleanup beyond what kitty needs | |

**User's choice:** Follow the profile

| Option | Description | Selected |
|--------|-------------|----------|
| Keep it, make it cheap | Keep fastfetch but non-blocking or trimmed | |
| Keep as-is | Accept fastfetch's cost, save elsewhere | ✓ (modified) |
| Drop it | Remove fastfetch from startup | |

**User's choice:** Keep fastfetch on every terminal (part of the experience), but trim it — remove heavy modules (Display Manager detection, slow disk/power polling) — and look for savings elsewhere (oh-my-posh, nvm, zinit).

| Option | Description | Selected |
|--------|-------------|----------|
| Vendor it in dotfiles | Local catppuccin theme JSON in zshell stow package | ✓ |
| Keep remote URL | Keep GitHub-hosted oh-my-posh config | |
| You decide | Planner picks based on profiling | |

**User's choice:** Vendor it in dotfiles

| Option | Description | Selected |
|--------|-------------|----------|
| Lazy-load | Defer nvm/bun until first invocation | ✓ |
| Keep synchronous | Eager loading, zero first-command latency | |
| You decide | Profile-driven | |

**User's choice:** Lazy-load

| Option | Description | Selected |
|--------|-------------|----------|
| No, fix the real cost | Per-window processes, fix actual startup | ✓ |
| Yes, use single-instance | kitty --single-instance for perceived speed | |
| Both | Fix cost AND single-instance | |

**User's choice:** No, fix the real cost

| Option | Description | Selected |
|--------|-------------|----------|
| Turbo/deferred load | zinit wait ices, async plugin load after prompt | ✓ |
| Prune plugins | Drop heaviest plugins | |
| Keep eager | Plugins fully active before first keystroke | |

**User's choice:** Turbo/deferred load

| Option | Description | Selected |
|--------|-------------|----------|
| Fallback in-phase | Shell replacement only if optimized zsh misses target | |
| Defer the switch | Optimize zsh only; migration is a later phase | |
| Evaluate now regardless | Benchmark zsh-optimized vs candidate side-by-side, pick winner | ✓ |

**User's choice:** Evaluate now regardless
**Notes:** User raised shell replacement unprompted: "If zshell proves to be a slow hindrance, we can consider replacing it with a faster shell."

| Option | Description | Selected |
|--------|-------------|----------|
| Fish | Fast + batteries included; built-ins replace zinit plugins | ✓ |
| Fish + Nushell | Both modern candidates | |
| Minimal zsh baseline | Stripped zsh to learn framework overhead | |

**User's choice:** Fish

---

## wlogout fix policy

| Option | Description | Selected |
|--------|-------------|----------|
| uwsm-correct actions | Rewrite actions to end the uwsm session cleanly | ✓ |
| Minimal diff | Change only what diagnosis directly implicates | |
| You decide | Diagnosis dictates fix shape | |

**User's choice:** uwsm-correct actions

| Option | Description | Selected |
|--------|-------------|----------|
| Audit all six | Verify every action against the uwsm session model | ✓ |
| Only shutdown/reboot | Fix only the named failures | |

**User's choice:** Audit all six

| Option | Description | Selected |
|--------|-------------|----------|
| Documented workaround | Cleanest workaround + documented upstream link | |
| Consider replacing wlogout | Evaluate alternatives rather than patch a dying tool | ✓ (modified) |
| Patch + upstream report | Workaround + file upstream issue | |

**User's choice:** If wlogout is broken upstream, evaluate alternatives now — user named **wleave** alongside a walker-based power menu.

| Option | Description | Selected |
|--------|-------------|----------|
| Function only in Phase 4 | Reliable power menu, current looks; redesign stays Phase 6 | ✓ |
| Replace + redesign together | Pull Phase 6 visual work forward | |

**User's choice:** Function only in Phase 4

---

## Hyprlock behavior trade-offs

| Option | Description | Selected |
|--------|-------------|----------|
| Drop it if implicated | grace = 0 if diagnosis confirms it contributes | ✓ |
| Keep grace | Preserve instant-unlock window | |
| You decide | Whatever is most reliable | |

**User's choice:** Drop it if implicated

| Option | Description | Selected |
|--------|-------------|----------|
| Right after manual lock | Keybind/menu lock, type immediately, chars vanish | ✓ |
| Waking from idle/suspend | First attempt fails on wake | |
| Both / not sure | No isolated pattern | |

**User's choice:** Right after manual lock

| Option | Description | Selected |
|--------|-------------|----------|
| Adopt it now | Write lockout-recovery procedure in Phase 4; Phase 6 reuses | ✓ |
| Informal for now | Keep a TTY open by habit; formalize in Phase 6 | |

**User's choice:** Adopt it now

| Option | Description | Selected |
|--------|-------------|----------|
| Config workaround OK | Config mitigation satisfies FIX-02 if root cause documented | ✓ |
| Consider alternatives | Evaluate other lockers if hyprlock fundamentally buggy | |
| Must fix in hyprlock | Keep hyprlock, escalate to upstream testing/patches | |

**User's choice:** Config workaround OK

---

## Verification depth

| Option | Description | Selected |
|--------|-------------|----------|
| Time to usable prompt | Keypress → interactive prompt, concrete budget (~400ms warm) | ✓ |
| Relative improvement | ≥50% faster + subjective sign-off | |
| Subjective only | Profile for cause; acceptance by feel | |

**User's choice:** Time to usable prompt

| Option | Description | Selected |
|--------|-------------|----------|
| N consecutive real cycles | 5 shutdown/reboot cycles, keyboard+mouse mix, clean journals | ✓ |
| Reproduce-then-verify | Build reliable reproducer first | |
| Few manual checks | Couple of successful shutdowns + clean journal | |

**User's choice:** N consecutive real cycles

| Option | Description | Selected |
|--------|-------------|----------|
| Scripted lock-type trials | ~10 trials, both trigger paths, 100% pass | ✓ |
| Manual-lock trials only | Focus where the drop happens; idle path smoke check | |
| Daily-use sign-off | Normal use for a few days | |

**User's choice:** Scripted lock-type trials

| Option | Description | Selected |
|--------|-------------|----------|
| One-time protocols | Documented in phase VERIFICATION records; no harness | ✓ |
| Kitty gate only | Rerunnable startup benchmark in verify/ | |
| Gates for everything | Script all three protocols | |

**User's choice:** One-time protocols

---

## Fish migration mechanics

| Option | Description | Selected |
|--------|-------------|----------|
| Full switch | New fish stow package, kitty launches fish, parity ported | ✓ |
| Kitty-only trial | Fish in kitty only; formalize later | |
| You decide | Planner picks safest shape | |

**User's choice:** Full switch

| Option | Description | Selected |
|--------|-------------|----------|
| Keep as fallback | zshell package stays installable | ✓ |
| Retire it | Remove once fish parity verified | |
| Decide after parity | Call it after daily-use proof | |

**User's choice:** Keep as fallback

| Option | Description | Selected |
|--------|-------------|----------|
| Prompt look (oh-my-posh) | Same catppuccin prompt from vendored config | ✓ |
| fzf + zoxide + completions | Equivalent fuzzy find, cd, completions | ✓ |
| fastfetch greeting | Trimmed fastfetch on every terminal | ✓ |
| Node tooling (nvm/bun) | node/npm/bun resolve correctly | ✓ |

**User's choice:** All four are day-one non-negotiable

| Option | Description | Selected |
|--------|-------------|----------|
| kitty shell config | `shell fish` in kitty.conf; login shell stays zsh | ✓ |
| chsh in install.sh | Fish as real login shell everywhere | |
| You decide | Planner researches uwsm/session interactions | |

**User's choice:** kitty shell config
**Notes:** User asked for clarification of the first two options before deciding; chose kitty-config approach after seeing the recovery-path and install.sh trade-offs.

---

## Shell benchmark decision rule

| Option | Description | Selected |
|--------|-------------|----------|
| Speed + feel, you judge | Executor presents numbers + trade-off note; user decides at checkpoint | ✓ |
| Fastest wins, automatic | Pure numbers pick the winner | |
| Fish only if zsh misses target | Conservative: zsh keeps seat if it hits budget | |

**User's choice:** Speed + feel, you judge

---

## Replacement preference order

| Option | Description | Selected |
|--------|-------------|----------|
| wleave first | Maintained near-drop-in wlogout fork; minimal migration | ✓ |
| Walker power menu now | Pull Phase 7 power menu forward | |
| Evaluate both, you pick | Prototype both, decide at checkpoint | |

**User's choice:** wleave first

---

## Diagnosis documentation home

| Option | Description | Selected |
|--------|-------------|----------|
| Phase dir records | SUMMARY/VERIFICATION per plan + PROJECT.md Key Decisions line | ✓ |
| docs/ troubleshooting file | Permanent symptom→cause→fix doc at repo root | |
| AUDIT.md style | v1.0-precedent single repo-root document | |

**User's choice:** Phase dir records

---

## Claude's Discretion

- Benchmark methodology (tooling, cold-vs-warm run counts, trial procedure)
- Exact fastfetch modules to trim beyond DM detection and disk/power polling
- Fish config file organization within the new stow package
- Precise uwsm-correct action commands (research the uwsm-documented pattern)

## Deferred Ideas

- Nushell as a second benchmark candidate — rejected for this phase (fish only)
- Retiring the zshell stow package — revisit after fish proves itself in daily use
- Permanent rerunnable reliability gates (e.g. kitty startup benchmark in verify/) — reconsider only if startup regresses again
