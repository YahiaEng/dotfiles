---
quick_id: 260827-ar3
date: 2026-08-27
status: complete
reversibility: one-way
completes: "Task 8 of quick task 260827-833"
commit: 7578f95c
---

# 260827-ar3 — Retire hyprlock — COMPLETE

hyprlock is gone from the repo and the host. `retirement-check hyprlock`
reports **`status=retired failed_classes=0`**; `theme-doctor` is **1330 passed,
0 failed**. This closes the one item owed by quick task 260827-833 and, with
it, the whole lock-screen migration.

## What was done

One commit, `7578f95c`, config-then-package per the `eww.scss` / WINDOWS #1
precedent, followed by `sudo pacman -Rns hyprlock` run by the operator.

**Deleted:** `hypr/.config/hypr/hyprlock.conf`,
`matugen/.config/matugen/templates/hyprlock-colors.conf`.

**Removed:** `[templates.hyprlock]` from `matugen/config.toml`; the
`hyprlock.conf` entry from `contract.json` (22 → 21 files); the
`/usr/bin/hyprlock` screencopy grant from `permissions.lua:129`; the package
from `install.sh:62`.

**Added:** the registry row
`hyprlock|retired|hypr/.config/hypr/hyprlock.conf|260827-833`.

**Host cleanup:** the dangling stow symlink `~/.config/hypr/hyprlock.conf` and
the orphaned matugen output `~/.local/state/theme/hyprlock.conf`.

**Package:** `pacman -Q hyprlock` now fails. `/etc/pam.d/hyprlock` and
`/usr/share/hypr/hyprlock.conf` went with it. `/etc/pam.d/passwd` is untouched.

## Three findings worth keeping

### 1. The brief's touchpoint count was wrong twice, and counting is cheap

The original brief said **seven** touchpoints; 260827-833's SUMMARY corrected it
to **ten**; a tree-wide grep found **25 files** carrying the string. The right
instrument was not a bigger list but a different question: not "which files
mention it" but "which files does `retirement-check` actually fail on". Those
are different sets, and only the second one is actionable. Classifying 25 files
against the gate's own 16 scan functions took one read of the gate and turned a
guess into a derivation.

**Reusable rule:** when a retirement brief hands you a touchpoint list, read the
gate that will judge it and derive the list yourself. The brief is a summary of
someone else's derivation and it decays.

### 2. Exactly one scan class skips comments — and I walked into it

`grep_hits(..., skip_comment_lines=True)` is passed by `scan_cross_package_refs`
and **no other scanner**. The gate's own comment says so explicitly: *"The ONE
caller that skips whole-line comments."* So comment prose is fatal in
`keybinds`, `contract-json`, `matugen-templates`, `test-fixtures` and
`install-stow-lists`, and harmless in every file cross-package-refs reaches.

I wrote a retirement note into `install.sh` that contained the word `hyprlock`,
which would have failed **class 10, install-stow-lists** — the exact gate this
task exists to turn green. Caught it on the post-edit grep, not by reasoning.
The note now deliberately does not name the surface and carries a comment saying
why, so the next person does not re-add it.

This is the second recorded instance of the "banned-identifier gate greps its
own prose" class. The first was a `//`-comment match in an earlier gate. The
shape is stable enough to expect: **after removing a token, grep for the token
again — your own changelog note is a reference.**

### 3. The one truly dangerous check was already answered, in code, by the author

`/etc/pam.d/hyprlock` is owned by the hyprlock package and disappears with
`-Rns`. That is the only way this removal could have locked the operator out.

It was safe because `LockPam.qml` uses `config: "passwd"`, and
`/etc/pam.d/passwd` is owned by **shadow 4.20.0.arch1-1**. The author of
260827-833 chose `"passwd"` *specifically* to survive this removal and wrote the
reasoning into the file header. The file needed no change today — the decision
working exactly as designed, a year-zero example of a comment paying for itself.

Verified independently via `pacman -Qo` on both files rather than trusting the
comment, per the project's own rule that a comment describes intent, not result.
Both facts held.

## Deliberately not done

- **`docs/superpowers/specs/2026-07-28-hyprland-lua-config-migration-design.md`**
  — 9 references, left untouched. Point-in-time design record, same treatment
  `v3.0-MILESTONE-AUDIT.md` got at the v3.0 close. `repo-prose` is report-domain
  (walker sits at 163 references with `failed_classes=0`), so this costs nothing.
- **Accurate historical comments** in `hypridle.conf`, `dynamic-cursors.lua`,
  `hypr-lua-harness`, `wallpaper-picker.sh`, `LockClock.qml`, `PowerMenu.qml`.
  They describe what was true when written and are reached only by the
  comment-skipping class.
- **`.claude/settings.local.json`** — untracked local permission allowlist,
  outside every scan class.

Prose that the removal made **false** rather than merely historical *was*
corrected: README's lock-screen row and two tree listings, the four "retirement
is HELD" comments in `PowerActions`/`Prefs`/`AppearancePage`/`LockContinuity`,
`LockPam.qml`'s PAM note (now past tense), and `wallpaper.sh`'s citation of a
now-deleted file.

## Gates

| Gate | Result |
|------|--------|
| `retirement-check hyprlock` | **`failed_classes=0`** — 14 blocking classes PASS/SKIP |
| `theme-doctor` | **1330 passed, 0 failed** |
| `theme-parity` | 1897 passed, 0 failed |
| `hypr-equivalence-check` | PASS 3, FAIL 0 |
| `keybind-doctor` | 13 passed, 0 failed |
| quickshell hot-reload | `Configuration Loaded` |

`pacman -Rsp hyprlock` printed exactly one package before removal, confirming no
dependency cascade — every dep is shared with hyprland.

## Operator note

The removed screencopy grant takes effect at the **next Hyprland restart**; the
live session still has it loaded. Harmless (it names a binary that no longer
exists), but the config and the running compositor differ until then.

`quickshell-doctor` was **not** run — it restarts the shell from inside, which
is forbidden from an agent shell. Available to the operator if wanted; nothing
in this task touched a surface it uniquely covers.
