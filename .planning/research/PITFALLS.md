# Pitfalls Research

**Domain:** Arch Linux + Hyprland dotfiles — unified GTK/walker/waybar/swaync theming pipeline (stow-managed)
**Researched:** 2026-07-07
**Confidence:** HIGH (grounded in direct inspection of this repo, the live host, and git history; cross-checked against Hyprland/GTK/Stow/Walker community documentation)

## Evidence base

This is not generic advice — every pitfall below is anchored to something found in this repo or on the live machine:

- `pacman -Q adw-gtk3` → **package not found**, on the very machine this dotfiles repo is deployed on, right now.
- `gtk/.config/gtk-3.0/settings.ini` hardcodes `gtk-theme-name=adw-gtk3-dark` and `install.sh` lists `adw-gtk3` in `AUR_PKGS` — yet it's absent.
- `~/.config/walker` and `~/.config/gtk-3.0`/`gtk-4.0` are **whole-directory stow symlinks** into the repo (confirmed via `ls -la`), and matugen's `config.toml` writes `output_path = "~/.config/walker/themes/rice/style.css"` etc. directly — i.e., matugen writes through the symlink into tracked repo files (confirmed via `git log` showing repeated commits touching these "auto-generated, do not edit" files).
- `stow.sh` runs `mv ~/.config/hypr/hyprland.conf ~/.config/hyprland.conf.bak` unconditionally, under `set -euo pipefail`, before any stow call — on a machine where nothing has been stowed yet, this path doesn't exist and the script aborts on line 1 of its real work.
- `debug.txt` (uncommitted, still in the tree) is a leftover diagnostic transcript from a prior failed fix attempt — it already found the `adw-gtk3` package missing and never connected that to the white-theme symptom before more script-level "fixes" were committed (`fix: gtk themes`, `debug: white theme`, `fix: walker and thunar not responding to theme changes`).
- Git history shows **8+ separate commits** trying to fix "walker/thunar white theme" over time, all patching scripts, none touching the dependency/install layer — a classic misdiagnosis loop.

## Critical Pitfalls

### Pitfall 1: Silent fallback to the default (white) theme when a hardcoded theme package is missing

**What goes wrong:**
GTK3 apps (Thunar, and any other GTK3 app) resolve `gtk-theme-name` from `settings.ini`/`GTK_THEME` at process start. If the named theme isn't installed, GTK does **not** error or warn — it silently falls back to the built-in default theme (Adwaita, which renders white/light). Nothing in the pipeline surfaces this failure: no log, no notification, no crash. It looks exactly like "theme switching is broken" when the actual fault is "the theme was never on disk."

**Why it happens:**
`install.sh` installs `adw-gtk3` via the AUR helper in one large batched call (`$AUR_HELPER -Sy --needed --noconfirm "${AUR_PKGS[@]}"` with ~15 packages). Batched AUR builds fail partially and silently more often than pacman batches — a single package's PKGBUILD/network/GPG hiccup can drop it from the transaction while the rest of the script continues (or the whole `install.sh` run predates the package being added to the list, or was interrupted). There is no post-install verification step that confirms packages the theming pipeline *hardcodes by name* (`adw-gtk3`, `adw-gtk3-dark`) actually landed. This is confirmed live: `pacman -Q adw-gtk3` reports "not found" on this exact machine, while three separate config surfaces (`gtk-3.0/settings.ini`, `hyprland.conf` env, `uwsm/env`) all hardcode `adw-gtk3-dark` as the theme name.

**How to avoid:**
- Add an explicit post-install verification block to `install.sh`: after package installation, loop over a short list of "theming-critical" packages (`adw-gtk3`, `gsettings-desktop-schemas`, `dconf`, `xdg-desktop-portal-gtk`) and `pacman -Q` each; hard-fail (or loudly warn with a summary) if any are missing rather than continuing silently.
- Add the same check to `theme-init.sh`/`theme-switch.sh` as a defensive guard: before applying `adw-gtk3-dark`, check `pacman -Q adw-gtk3 &>/dev/null`; if missing, notify-send a loud error ("adw-gtk3 not installed — GTK apps will render default theme") instead of proceeding as if it worked.
- Prefer per-package `paru -S` calls (or checking exit status per package) over one giant batched AUR array, so a single failure is attributable and doesn't hide inside a 15-package transaction.

**Warning signs:**
- `pacman -Q adw-gtk3` (or any hardcoded theme/cursor/icon package) returns "not found" despite install.sh listing it.
- GTK3 apps render with default Adwaita chrome (white background, blue accent) regardless of which custom theme is "active" per `~/.cache/current-theme`.
- No errors anywhere in logs — the absence of an error *is* the symptom.

**Phase to address:** The bug-scan/theming-fix phase (Milestone 1, Active requirement "Thunar/GTK apps follow theme switches") — this should be the **first** thing checked, before touching any propagation script, since it is very likely the actual root cause of the reported symptom.

---

### Pitfall 2: Theme-generation scripts write "auto-generated" output directly into the git repo via stow's whole-directory symlinking

**What goes wrong:**
`stow`'s tree-folding collapses an entire package directory into a *single* symlink when nothing else contends for it (confirmed: `~/.config/walker -> ../dotfiles/walker/.config/walker`, `~/.config/gtk-3.0 -> ../dotfiles/gtk/.config/gtk-3.0`, whole directories, not per-file links). Matugen's `config.toml` then writes generated, per-wallpaper color output straight to `output_path = "~/.config/walker/themes/rice/style.css"` and `~/.config/gtk-3.0/colors.css` — which, through the symlink, is physically `~/dotfiles/walker/.config/walker/themes/rice/style.css` and `~/dotfiles/gtk/.config/gtk-3.0/colors.css` **inside the git working tree**. `git log` confirms these files have been repeatedly committed as if they were source, with commit messages like "fix: walker theme background" — generated runtime state is being versioned as if it were configuration.

**Why it happens:**
The repo doesn't separate "template/config source" from "generated/runtime output." Because stow folds the whole `walker/` and `gtk/` package trees into one symlink each (there's no competing package writing into those same paths), every file under them — including files a script intends to treat as scratch/cache — lives inside the repo. The existing scripts already show awareness of half of this problem (`theme-init.sh` explicitly does `[[ -L "$WALKER_DIR" ]] && rm -f "$WALKER_DIR"` to defend against the *rice subdirectory itself* becoming a symlink) but this check is a no-op in practice: the symlink lives at the `~/.config/walker` level (the whole package), so `~/.config/walker/themes/rice` is never itself a symlink — it's a real directory *because it's already inside the symlinked tree*. The guard checks the wrong path.

**Consequences:**
- Every theme switch produces an uncommitted (or worse, committed) diff in the repo, polluting `git status`/`git diff` with generated noise, exactly what's visible in the current `git status` (modified `wallpapers/.../current.jpg`, etc.).
- A fresh `git clone` + `stow.sh` on a new machine starts with whatever theme colors were last committed baked into these "generated" files, not a clean/default state, and not necessarily matching `~/.cache/current-theme`.
- Risk of merge conflicts / accidental commits of machine-specific, wallpaper-derived color data.
- If a second package ever needs a path under `.config/walker/` or `.config/gtk-3.0/`, stow will be forced to "unfold" the tree-folding symlink into a real directory with per-file symlinks — silently changing this exact behavior and potentially breaking scripts that assume `[[ -L "$WALKER_DIR" ]]` semantics.

**How to avoid:**
- Redirect matugen `output_path` (and the static-theme `cp` targets) to a **non-stowed, non-repo location** — e.g., `~/.local/state/theme/` or `~/.cache/theme/` — and have each app's stowed config `@import` or read from that external path instead of a path that lives inside the stow-managed tree. This is the standard fix: keep "what stow manages" (declarative config) and "what the theme engine writes" (generated runtime state) in disjoint directories.
- Alternative if outputs must stay under `~/.config/<app>/`: mark the generated leaf files (not the whole package) with `.gitignore` and ensure stow only symlinks the static parts (requires restructuring so the generated file's parent directory is *not* the sole content of the package, forcing per-file symlinks instead of directory folding).
- Add the generated paths to `.gitignore` at minimum, even if the structural fix above isn't done yet, so accidental commits stop.

**Warning signs:**
- `git status` shows changes to `colors.css`, `style.css`, or `gtk.css` after simply switching themes or wallpapers, with no manual edit.
- `find ~/.config/<app> -type l` shows the *parent* directory itself is the symlink, not the leaf files — meaning anything written "into" that tree lands in the repo.
- `git log -- <theme-output-file>` shows a long history of automated-looking commits.

**Phase to address:** The bug-scan/theming-fix phase — this is core to the "unified theming pipeline" requirement and should be fixed structurally, not patched per-app (per PROJECT.md: "the root cause is likely in GTK theme propagation and has resisted per-app patching" — this symlink/output-path conflation is very likely a contributing structural cause of that resistance).

---

### Pitfall 3: GTK3 apps cannot hot-reload theme or CSS — "restart" is fragile for single-instance apps like Thunar

**What goes wrong:**
GTK3 reads `gtk-theme-name` and user `gtk.css` once at process startup; there is no live-reload mechanism (this is explicitly correct in the repo's own `gtk-reload.sh` comment). The only way to re-theme a running GTK3 app is to kill and relaunch its process. Thunar additionally runs as a **D-Bus single-instance daemon** (`org.xfce.Thunar`) — opening "another" Thunar window normally just messages the existing daemon rather than starting a fresh themed process. `gtk-reload.sh` does attempt the correct sequence (`thunar --quit`, `sleep 0.5`, relaunch `--daemon`), but this is timing-sensitive: if the D-Bus quit hasn't fully deregistered before the relaunch fires, the new process can attach to the still-dying old daemon instead of starting fresh, silently keeping the old (wrong) theme alive. `thunar-volman`/`tumbler` (also GTK3, autostarted independently of Thunar's main process) are not restarted by this script at all, so file-manager-adjacent dialogs they own can stay stuck on the old theme indefinitely.

**Why it happens:**
Treating "restart the app" as equivalent to "reload the theme" is correct in principle but requires precise process-lifecycle handling per app; GTK3's single-instance/D-Bus activation model makes this more fragile than it looks, especially with fixed `sleep` delays instead of waiting for an actual signal (D-Bus name released, PID gone).

**How to avoid:**
- Replace the fixed `sleep 0.5` with a poll loop that waits until `pgrep -x thunar` returns nothing (bounded, e.g. up to 2s) before relaunching, so the restart is deterministic instead of timing-guessed.
- Explicitly restart `tumbler` (thumbnailer daemon) alongside Thunar if it's found running, since it's a separate GTK3 process outside Thunar's own D-Bus lifecycle.
- Only restart Thunar if it was actually running before the theme switch (already partially done via `pgrep -x thunar`) — but also handle the case where Thunar has open windows/unsaved state (e.g., mid rename, mid file operation) by warning rather than force-killing, since `--quit` on a busy daemon can lose UI state.

**Warning signs:**
- Theme switch "sometimes" fixes Thunar and "sometimes" doesn't, without code changes — a signature of a race condition, not a logic bug.
- Thunar reflects the new theme but file dialogs, thumbnail popups, or archive-manager windows don't.

**Phase to address:** Bug-scan/theming-fix phase, specifically the Thunar/GTK requirement.

---

### Pitfall 4: Walker's theme cache and non-hotreloading default fight the "generate-then-restart" approach

**What goes wrong:**
Walker mirrors theme assets into `$XDG_DATA_HOME/walker/themes/<name>/` separately from `$XDG_CONFIG_HOME/walker/themes/<name>/`, and by default does **not** hot-reload CSS (`hotreload_theme` config key, currently unset/false in this repo's `config.toml`). The repo's scripts already fight this by deleting `~/.local/share/walker/themes/rice` and killing/relaunching the `walker --gapplication-service` process on every theme switch (`walker-restart.sh`), which is heavier and slower than necessary, and races with the separately-running `elephant` provider backend that Walker depends on for search results — if `elephant` isn't fully up (or is itself mid-restart) when Walker reconnects, providers can silently return zero results, which looks like a theme bug but is actually a provider-connection bug.

**Why it happens:**
Walker's config surface (`hotreload_theme`) that would remove the need for kill/relaunch entirely wasn't enabled, so the repo compensates with a more invasive and fragile restart-based workaround (kill, `sleep`, socket cleanup, relaunch via `uwsm app --`).

**How to avoid:**
- Set `hotreload_theme = true` in `walker/.config/walker/config.toml` and re-test whether a plain CSS overwrite (no process restart) is picked up — this is the documented, supported mechanism and removes an entire class of restart-timing bugs.
- If a restart is still needed for non-CSS config changes, don't restart `elephant` in the same pass unless its config also changed — keep the two daemons' lifecycles independent so one doesn't starve the other during a rapid theme-then-search sequence.
- Verify `~/.config/walker/config.toml`'s `theme = "rice"` still resolves after any config-path change (Walker looks in both config and data theme dirs; a stale copy in one can silently take precedence over the freshly generated one in the other).

**Warning signs:**
- Walker looks un-themed only immediately after a switch, then looks correct after a manual `killall walker` — indicates a restart-not-taking-effect / stale-cache issue rather than a CSS-content issue.
- Walker launches but shows no search results right after a theme switch, recovering after a few seconds — indicates an `elephant` provider race, not a Walker theming bug (don't misattribute this to CSS work).

**Phase to address:** Bug-scan/theming-fix phase, Walker requirement.

---

### Pitfall 5: `install.sh` cannot run on the fresh system it claims to support

**What goes wrong:**
`stow.sh` (invoked by the documented install flow: `install.sh` then `stow.sh`) begins its actual stow work with:
```bash
mv ~/.config/hypr/hyprland.conf ~/.config/hyprland.conf.bak
```
under `set -euo pipefail`, with no existence check. On a genuinely fresh Arch install, `~/.config/hypr/hyprland.conf` does not exist yet (nothing has been stowed) — `mv` fails, and the script aborts immediately, before stowing a single package. The documented "reproduces from scratch with one script" core value is currently false as written.

**Why it happens:**
The line was almost certainly added to handle *re-runs* on an already-stowed machine (back up a real file before `stow --restow` would otherwise conflict with it) but was never guarded for the "nothing exists yet" first-run case.

**How to avoid:**
- Guard the backup: `[[ -e ~/.config/hypr/hyprland.conf && ! -L ~/.config/hypr/hyprland.conf ]] && mv ~/.config/hypr/hyprland.conf ~/.config/hyprland.conf.bak`.
- More generally, audit `stow.sh` and `install.sh` for every unconditional operation that assumes prior state (existing files, existing directories, already-running services) and add existence/idempotency guards — this is the single highest-value thing the "verify install.sh on a clean Arch system" active requirement should check first, since it currently fails at the first meaningful line.
- Test the full flow in a disposable Arch container/VM, not just `--restow` on the already-provisioned dev machine (which never exercises the fresh-system path).

**Warning signs:**
- Running `stow.sh` on a container/VM with a bare Arch + this repo cloned exits non-zero immediately with an `mv: cannot stat` error.
- The only environment this has ever been tested on is the live dev machine, which has been stowed for months — the fresh-install path is unverified by construction (this matches PROJECT.md's own flag: "existing (needs re-verification)").

**Phase to address:** install.sh verification phase (explicit Active requirement).

---

### Pitfall 6: `stow --restow` fails or silently no-ops when the target directory pre-exists as real (non-stow) content

**What goes wrong:**
GNU stow's tree-folding only collapses a target into a single symlink when the target is empty or entirely stow-owned. Config directories this pipeline hardcodes into (`~/.config/gtk-3.0`, `~/.config/gtk-4.0`, `~/.config/Thunar`, `~/.config/walker`) are commonly auto-created with real (non-symlink) default content the moment the corresponding package is installed and any GTK app launches even once before `stow.sh` runs (e.g., a display-manager greeter, or `install.sh`'s own `vscodium-extensions.sh` post-install step launching a GTK-backed tool). When that happens, `stow --restow` reports conflicts on individual files ("existing target is neither a link nor a directory") and leaves that package only partially applied — with `set -euo pipefail` in `stow.sh` NOT applied to the stow loop itself (each `stow --restow` call is piped through `sed`, whose own exit status masks stow's), a conflict can be silently swallowed and the loop continues, giving a false "stowed successfully" summary while a package silently failed to link.
This is exactly why `~/.config/Thunar` on the live machine (confirmed via `ls -la`) is a *real* directory with individually-symlinked `thunarrc`/`uca.xml` sitting alongside a real, non-stowed `accels.scm` — proof that tree-folding did NOT happen here and a partial/per-file link state is the norm for at least one already-broken package.

**Why it happens:**
Piping `stow --restow ... | sed '...'` discards stow's exit code (the pipeline's exit status is `sed`'s, not stow's), so `set -euo pipefail`'s `pipefail` option is the only thing that would catch this — and it's present in `stow.sh`'s shebang preamble, so a real conflict *should* currently abort the script. But this makes failures all-or-nothing at the package level with no per-package summary, and doesn't help the fresh-install case where the *first* package to conflict (whichever is alphabetically/array-order first) blocks everything after it silently mid-run.

**How to avoid:**
- Run `stow --restow --verbose=1` (or check its exit code explicitly per package rather than relying on `pipefail` propagation through `sed`) and print an explicit per-package PASS/FAIL summary at the end of `stow.sh`.
- Before stowing GTK/Thunar-related packages, proactively check for and clear conflicting real files/directories left behind by first-run app defaults (or document that `stow.sh` must run before any GTK app is ever launched on a fresh account).
- Treat "`~/.config/Thunar` is a real directory instead of a symlink" as a detectable health-check signal (`[[ -L ~/.config/Thunar ]]` should be false only for the specific pre-existing files, not the confusing partial state currently present).

**Warning signs:**
- `stow.sh` reports "stowed successfully" but `find ~/.config/<pkg> -maxdepth 1 -type l` shows it isn't actually a symlink (or isn't fully linked).
- Editing a file under the repo's package directory doesn't appear to affect the live config, or vice versa — a sign the live path isn't actually linked to the repo copy.

**Phase to address:** install.sh / repo-cleanup verification phase, alongside Pitfall 5 (both live in `stow.sh`).

---

### Pitfall 7: GTK theme/env state is declared in three uncoordinated places that can silently drift

**What goes wrong:**
`GTK_THEME=adw-gtk3-dark` is hardcoded independently in: `hypr/.config/hypr/config/env.conf` (Hyprland `env =`), `uwsm/.config/uwsm/env` (uwsm-managed environment), and re-exported at runtime inside `gtk-reload.sh`. These three are read at different times by different managers (Hyprland's own env table at compositor start; uwsm's environment daemon at session start; the script's own shell at theme-switch time), and Hyprland's `env =` directive does **not** propagate to systemd user services or D-Bus-activated apps — only to processes Hyprland itself execs. Under a uwsm-managed session, uwsm's environment is what actually reaches most autostarted and D-Bus-activated apps, making the `hyprland.conf` copy mostly redundant, but not obviously so — someone editing only one of the three (e.g., adding a "light" static theme variant later) will get inconsistent results depending on how a given app was launched (Hyprland-execed vs. D-Bus-activated vs. uwsm-scoped).

**Why it happens:**
uwsm and Hyprland both have their own environment-propagation models, and mixing them (as this repo does, correctly per uwsm's own recommended pattern for "Hyprland-internal vars only" in `env.conf`) still leaves cross-cutting values like `GTK_THEME` easy to duplicate rather than centralize.

**How to avoid:**
- Keep exactly one authoritative source for `GTK_THEME` (the `uwsm/env` file, since uwsm is the actual session manager here) and remove the duplicate from `hypr/config/env.conf` unless a specific Hyprland-exec-only process needs it directly.
- If the value needs to change at runtime (future light/dark or per-theme GTK_THEME variants), route all writers through one script (already `gtk-reload.sh`) that updates the systemd/dbus activation environment, and stop hardcoding the same literal in multiple files that a future contributor might edit only one of.

**Warning signs:**
- An app behaves correctly when launched from a terminal inside the session but wrong when launched via its `.desktop` file (or vice versa) — a signature of environment-source mismatch.
- `systemctl --user show-environment | grep GTK_THEME` and `hyprctl` (or Hyprland's own env introspection) disagree.

**Phase to address:** Bug-scan/theming-fix phase — lower priority than Pitfalls 1–4, but worth a cleanup pass while touching this code.

---

### Pitfall 8: (Forward-looking) GTK4/libadwaita apps ignore GTK3-style theme names — only light/dark is themeable without much deeper work

**What goes wrong:**
This repo currently has no GTK4/libadwaita apps in the active app set (Thunar is GTK3; VSCodium is Electron), but Milestone 2 items (custom walker menus "in the style of Omarchy," OSD indicators, a media center) are exactly the kind of feature that tends to pull in a GTK4/libadwaita component later. GTK4 apps do not read `gtk-theme-name` the way GTK3 does — libadwaita intentionally only exposes a light/dark toggle (`org.gnome.desktop.interface color-scheme`) plus a small named-color palette (`accent_color`, `window_bg_color`, etc., the same names already used in this repo's `gtk-4.0/gtk-base.css` scheme) via CSS custom properties. There is no equivalent of "pick an arbitrary named GTK4 theme" — accent color is either the system accent (GNOME-only) or must be forced by overriding the exact libadwaita CSS variables, which is fragile across libadwaita version bumps (hardcoded internal class/variable names sometimes change between versions).

**How to avoid:**
- If any future phase adds a GTK4/libadwaita app, theme it exclusively through `@define-color` overrides in `~/.config/gtk-4.0/gtk.css` (the pattern already used here) rather than trying to find/install a "GTK4 theme package" (they mostly don't exist/work the way GTK3 themes do).
- Keep `color-scheme` (light/dark) and "accent hue" (matugen/static palette) as two independently-set concerns — don't assume one config key controls both, since libadwaita treats them separately.

**Phase to address:** Any future phase that introduces a new GTK4-based component (Milestone 2+); not urgent for Milestone 1.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|-----------------|------------------|
| Killing/relaunching whole processes (Thunar, Walker) instead of true hot-reload | Simple, doesn't require per-app reload APIs | Race conditions, lost UI state, slower perceived theme switch | Acceptable for GTK3 apps (no hot-reload exists); should be replaced with hot-reload where the app supports it (Walker's `hotreload_theme`) |
| Matugen writing straight into stow-managed config paths | One config file (`matugen/config.toml`) is the single source of truth for output locations | Generated state gets versioned in git; symlink-folding surprises | Never acceptable long-term for a repo meant to `git clone` cleanly onto a new machine |
| Fixed `sleep N` delays instead of polling for process/service readiness (`walker-restart.sh`, `gtk-reload.sh`, autostart `sleep 2 && theme-init.sh`) | Simple, no dependency on extra tooling | Flaky under load/slow hardware; masks real race conditions as "intermittent" bugs | Acceptable only as a temporary stopgap; should be replaced with an explicit wait-for-condition loop before Milestone 1 closes |
| Hardcoding `GTK_THEME=adw-gtk3-dark` in 3 files instead of one | Each subsystem "just works" without cross-file wiring | Drift risk when one is edited and others aren't | Acceptable only if consolidated to a single source once the pipeline stabilizes |
| Batched AUR installs of 15+ packages in one call | Fewer lines in `install.sh` | Partial/silent failures are hard to attribute (see Pitfall 1) | Never acceptable for packages the pipeline hardcodes by name; fine for genuinely optional/personal packages (browsers, Discord, etc.) |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|-----------------|-------------------|
| matugen → GTK/Walker/waybar/swaync | Pointing `output_path` at a path stow has folded into a repo symlink | Point `output_path` at a non-stowed runtime/state directory (`~/.local/state/theme/…` or `~/.cache/…`); have stowed app configs `@import`/reference that external path |
| GNU stow ↔ first-run app defaults | Assuming `~/.config/<app>` is always empty before first stow | Run `stow.sh` before ever launching the target apps, or add pre-flight cleanup of known default files (`gtk-3.0/settings.ini`, `Thunar/accels.scm`, etc.) |
| uwsm ↔ Hyprland `env =` | Assuming `env =` in `hyprland.conf` reaches D-Bus/systemd-activated apps | Set cross-cutting env vars once in `uwsm/env`, reserve `hyprland.conf` `env =` for compositor-internal-only vars (cursor size/theme are fine there since Hyprland itself needs them) |
| Walker ↔ elephant | Restarting Walker without regard to elephant's readiness | Only restart Walker's process if theme/config actually changed; don't bundle elephant restarts into every theme switch unless elephant's own config changed |
| xdg-desktop-portal-gtk ↔ GTK4 apps | Assuming the portal alone re-themes GTK4 apps | Portal only carries `color-scheme` (light/dark) via `org.freedesktop.impl.portal.Settings`; accent/palette still needs `gtk.css` `@define-color` overrides per Pitfall 8 |
| xfconf (`xsettings.xml`) ↔ Thunar | Assuming xfconf's `Net/ThemeName` alone re-themes Thunar under Wayland | xfconf's XSettings mechanism is an X11-era channel; under Hyprland (Wayland-native) GTK3 apps resolve theme via `settings.ini`/`GTK_THEME`, not XSettings — treat the xfconf file as informational for Thunar's own preferences (icon size, cursor), not the primary GTK theming path |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|-----------------|
| Full theme-switch pipeline runs `hyprctl reload`, 2 `pkill` signals, `swaync-client -rs`, a GTK rebuild+concat, a Walker kill/relaunch, and a Thunar kill/relaunch on every single switch, several with `sleep` | Theme switch feels sluggish (~1-2s+) even though most apps (waybar/swaync/kitty) support instant CSS/signal-based reload | Skip restarting apps that weren't running (already partially done for Thunar via `pgrep`); make Walker reload via `hotreload_theme` instead of full process kill | Noticeable on every switch today; will get worse if more apps are added to the reload chain (Milestone 2 media center, OSD) without similar guards |
| Walker `--gapplication-service` has a known upstream memory growth issue over long uptimes | RAM usage climbs the longer the session stays open | Not fully avoidable from this repo alone; periodic restart (already happens incidentally on each theme switch) mitigates it as a side effect — track upstream Walker releases for fixes | Long-running sessions (multi-day uptime), not an issue for typical daily reboots |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| `install.sh` runs `chmod +x` on every `*.sh` under a freshly cloned repo, and `curl`-less AUR builds run arbitrary `makepkg` from AUR packages with `--noconfirm` (including a hand-picked list of personal AUR packages like `1password`, `spotify`, `discord`) | Blind `--noconfirm` AUR installs skip the interactive PKGBUILD review that's the normal safety net for AUR | Keep `--noconfirm` only for pacman (official, signed repos); drop it for the AUR helper call, or document that PKGBUILDs should be reviewed at least once per package before first install |
| `paru -R "$(pacman -Qtdq)"` (blind orphan removal) runs unconditionally at the end of `install.sh` | Can remove packages the user didn't expect to lose, especially right after installing something that briefly looks orphaned | Print the list first and require confirmation, or scope orphan removal to a manually reviewed step outside the main install flow |
| `notify-send` calls embed error output directly (`cat /tmp/matugen-error.log`) into a desktop notification | Low risk here (single-user personal machine), but arbitrary command output surfaced in a notification banner is generally worth sanitizing | Truncate/sanitize error output before displaying; keep full detail only in the log file |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|--------------|-------------------|
| PROJECT.md promises "no relogin/restart required," but `debug.txt` (leftover in the tree) explicitly instructs "log out and log back in before testing" for GTK_THEME propagation | Contradicts the stated core value; if a relogin is genuinely still needed anywhere, the requirement is unmet | Verify mid-session `dbus-update-activation-environment`/`systemctl --user import-environment` calls in `gtk-reload.sh` actually make relogin unnecessary in practice, and remove/update the stale `debug.txt` note once confirmed |
| A theme switch fires a `notify-send` popup every time, on top of the visual change itself | Minor but repetitive interruption for something that's already visually obvious | Consider making the notification optional/quieter, or only shown on error |
| Silent failure modes (Pitfall 1, Pitfall 4's elephant race) look identical to "the whole theming system is broken" from the user's seat | Wastes debugging time chasing the wrong subsystem (exactly what happened across 8+ "fix" commits) | Add minimal diagnostic notifications/logging at each pipeline stage so failures are attributable to a specific step, not "theming is broken" in general |

## "Looks Done But Isn't" Checklist

- [ ] **"Thunar follows theme switches":** Often looks fixed right after editing `gtk.css`/`settings.ini` in the repo, but GTK3 needs a full process restart to pick it up — verify by actually killing and relaunching Thunar, not just re-cat-ing colors.
- [ ] **"Walker follows theme switches":** Often looks fixed because the generated `style.css` content is correct, but if `~/.config/walker`'s stow-symlink status or the `~/.local/share/walker/themes/rice` shadow cache isn't also checked, a stale cached copy can still be what's rendered.
- [ ] **"install.sh produces a working themed setup on a clean Arch system":** Often "verified" by re-running on the existing dev machine (`stow --restow`), which never exercises the true fresh-system code path (Pitfall 5) — must be tested in a disposable VM/container with a bare Arch image.
- [ ] **"All theme-critical packages installed":** Often assumed true because they're listed in `install.sh`'s package arrays — verify with `pacman -Q <pkg>` after a real install run, not by reading the script (Pitfall 1 proves listing ≠ installed).
- [ ] **"Waybar/swaync re-theme correctly":** Likely lower risk (both use plain `@import url("colors.css")` + explicit reload signals rather than system GTK theme resolution) but still unverified per PROJECT.md — confirm with an actual wallpaper-driven Material You switch, not just a static preset switch, since matugen's `post_hook`s differ per template.
- [ ] **"Repo cleanup — stow applies cleanly":** Often looks clean because `stow --restow` succeeds on an already-stowed machine — verify by checking `find ~/.config/<pkg> -type l` actually reflects full-package symlinks where expected, not partial/real-directory states left over from earlier conflicts (Pitfall 6).

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|-----------------|------------------|
| Missing `adw-gtk3` (Pitfall 1) | LOW | `paru -S adw-gtk3`, then restart any running GTK3 apps (or relogin) — no data loss, just a package install |
| Generated files committed into repo (Pitfall 2) | MEDIUM | Move output paths out of the stowed tree, `git rm --cached` the generated files, add to `.gitignore`; requires a one-time repo history cleanup decision (rewrite vs. leave history as-is) |
| `stow.sh` aborting on fresh install (Pitfall 5) | LOW | Add the existence guard around the `mv`; re-run |
| Partial/conflicted stow state (Pitfall 6) | MEDIUM | `stow -D <pkg>` to fully unlink, manually remove leftover real files/dirs, `stow <pkg>` again from clean state |
| Walker stuck on stale cached theme (Pitfall 4) | LOW | `rm -rf ~/.local/share/walker/themes/rice && killall walker` then relaunch via `uwsm app -- walker --gapplication-service` |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|----------------|
| 1. Missing hardcoded theme package (adw-gtk3) | Bug-scan/theming-fix phase (do this check FIRST) | `pacman -Q adw-gtk3 gsettings-desktop-schemas dconf xdg-desktop-portal-gtk` all resolve; add automated check to install.sh |
| 2. Generated theme output committed through stow symlinks | Bug-scan/theming-fix phase | `git status` clean after a theme switch; matugen `output_path`s point outside any stow-managed tree |
| 3. GTK3 (Thunar) restart fragility | Bug-scan/theming-fix phase | Switch themes 10x in a row with Thunar open each time; confirm 100% correct re-theme, not "usually works" |
| 4. Walker cache/hotreload | Bug-scan/theming-fix phase | `hotreload_theme = true` set; theme switch updates Walker CSS without a full process kill/relaunch |
| 5. `stow.sh` fresh-install abort | install.sh verification phase | Full `install.sh` + `stow.sh` run succeeds unattended in a disposable Arch VM/container from a bare image |
| 6. Partial stow-fold conflicts | install.sh verification phase / repo cleanup phase | `find ~/.config/<pkg> -type l` matches expected symlink topology for every stowed package |
| 7. GTK_THEME declared in 3 places | Bug-scan/theming-fix phase (low priority cleanup) | Single authoritative source; `systemctl --user show-environment` matches hyprctl-visible env |
| 8. GTK4/libadwaita theming limits | Any future phase adding a GTK4 component | New component follows the `gtk.css` `@define-color` override pattern, not a "theme name" approach |

## Sources

- Direct inspection of this repo: `install.sh`, `stow.sh`, `gtk/`, `walker/`, `thunar/`, `matugen/`, `themes/`, `hypr/.config/hypr/scripts/*.sh`, `hypr/.config/hypr/config/*.conf`, `uwsm/.config/uwsm/env*`, `.stow-local-ignore`, `.gitignore` — HIGH confidence (primary source, this is the actual project).
- Live host inspection: `pacman -Q adw-gtk3` / `gsettings-desktop-schemas`, `gsettings get org.gnome.desktop.interface {gtk-theme,color-scheme}`, `ls -la ~/.config/{walker,gtk-3.0,gtk-4.0,Thunar}`, `systemctl --user status xdg-desktop-portal*.service`, live process list — HIGH confidence (direct empirical evidence from the exact machine this milestone targets).
- Git history (`git log --oneline` on theming-related paths) and leftover `debug.txt` — HIGH confidence (primary source, shows prior failed fix attempts and a half-diagnosed root cause).
- [GNU Stow manual — tree folding/splitting semantics](https://www.gnu.org/software/stow/manual/stow.html) — HIGH confidence (official docs), corroborated by community write-ups (System Crafters, Bastian Venthur's blog) on the "generated files land in the repo through folded symlinks" gotcha.
- [Hyprland Wiki FAQ](https://wiki.hypr.land/FAQ/) and [Hyprland Discussion #5867 "How to set dark mode?"](https://github.com/hyprwm/Hyprland/discussions/5867) — MEDIUM-HIGH confidence (official/maintainer-adjacent community sources) on gsettings/dconf/portal requirements for GTK3 vs GTK4 theme switching under Hyprland.
- [xdg-desktop-portal-hyprland issue #171 — GTK4 theme change ignored](https://github.com/hyprwm/xdg-desktop-portal-hyprland/issues/171) and [Arch Forums — GTK4 theming with nwg-look on Hyprland](https://bbs.archlinux.org/viewtopic.php?id=310005) — MEDIUM confidence (community reports), consistent with Pitfall 8's GTK4/libadwaita constraints.
- [Walker launcher documentation (walkerlauncher.com)](https://walkerlauncher.com/docs/installation) and [Walker GitHub repo](https://github.com/abenz1267/walker) — MEDIUM confidence (project docs/community), source for `hotreload_theme` config option and the Elephant-backend dependency, and the known `--gapplication-service` memory-growth issue.

---
*Pitfalls research for: Arch Linux + Hyprland dotfiles theming pipeline*
*Researched: 2026-07-07*
