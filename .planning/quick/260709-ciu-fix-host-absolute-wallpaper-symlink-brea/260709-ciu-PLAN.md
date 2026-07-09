---
phase: quick
plan: 260709-ciu
type: execute
wave: 1
depends_on: []
files_modified:
  - wallpapers/Pictures/Wallpapers/current.jpg
  - hypr/.config/hypr/scripts/wallpaper-picker.sh
autonomous: true
requirements: [INST-03]

must_haves:
  truths:
    - "readlink of the tracked current.jpg symlink prints a bare relative filename (shaded-landscape.jpg), never a /home/... absolute path"
    - "generate.sh's materialyou branch finds a real file behind current.jpg on a fresh stow'd install, so theme-parity's materialyou case passes out of the box"
    - "picking a wallpaper never rewrites current.jpg back to a host-absolute target — the picker stores a filename-only relative link"
  artifacts:
    - "wallpapers/Pictures/Wallpapers/current.jpg (tracked symlink, mode 120000, stored target 'shaded-landscape.jpg')"
    - "hypr/.config/hypr/scripts/wallpaper-picker.sh (link-creation at line ~124 uses ln -sfr)"
  key_links:
    - "generate.sh readlink -f (line 32) resolves a relative symlink target against the symlink's own directory — no engine change needed; the relative link Just Works after stow"
    - "wallpaper-picker.sh CURRENT_LINK and FULL_PATH both live in WALLPAPER_DIR, so ln -sfr collapses the stored target to the bare filename"
---

<objective>
Fix the INST-03 gate finding: the git-tracked wallpaper symlink `wallpapers/Pictures/Wallpapers/current.jpg` stores an ABSOLUTE, host-only target (`/home/aorus/Pictures/Wallpapers/shaded-landscape.jpg`), so on a fresh install the link dangles for any other user. The theme engine's materialyou branch requires a real file behind `current.jpg`, so a fresh install fails theme-parity's dynamic case (gate run 20260709T054046Z: theme-parity 246 passed, 1 failed — "materialyou: theme_engine_generate succeeded"; all 6 static presets pass). A committed host-absolute path also violates the project's reproducibility constraint.

Two edits, one defect, one commit:
1. Re-create the tracked symlink with a RELATIVE target (`shaded-landscape.jpg`). A relative target resolves per-user after stow, so fresh installs get a working default wallpaper and materialyou renders out of the box.
2. Change the wallpaper picker's link-creation from `ln -sf` (absolute) to `ln -sfr` (GNU relative) so future wallpaper picks stop re-writing the tracked symlink to a host-absolute path.

Purpose: make the default-wallpaper state reproducible on a fresh Arch + stow install and stop the picker from re-introducing host-only state into the repo.
Output: a relative tracked symlink + a picker that only ever stores relative links.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@hypr/.config/hypr/scripts/wallpaper-picker.sh
</context>

<tasks>

<task type="auto">
  <name>Task 1: Make the current.jpg symlink relative (tracked file + picker)</name>
  <files>wallpapers/Pictures/Wallpapers/current.jpg, hypr/.config/hypr/scripts/wallpaper-picker.sh</files>
  <action>Two changes for the same defect.

PART A — re-create the tracked symlink relative. From the repo root run `ln -sfn shaded-landscape.jpg wallpapers/Pictures/Wallpapers/current.jpg`. `ln` stores the target argument verbatim, so the stored target becomes exactly `shaded-landscape.jpg` (a bare filename, no leading slash). `shaded-landscape.jpg` is a git-tracked regular file (~4 MB) in the SAME directory, so the link resolves against the symlink's own directory for every user after stow. Use `-n` so an existing `current.jpg` symlink is replaced rather than dereferenced. Do NOT retarget to `shaded_landscape.png` — the tracked/default wallpaper is `shaded-landscape.jpg` (hyphens, .jpg). After re-creating it, stage it with `git add wallpapers/Pictures/Wallpapers/current.jpg` so the index records the new blob at mode 120000 (git preserves symlink mode automatically; the change is a symlink→symlink retarget, never a symlink→regular-file conversion).

PART B — stop the picker from writing absolute links. In hypr/.config/hypr/scripts/wallpaper-picker.sh, the single link-creation site (currently at line ~124, the only `ln -s` in the file) links the selected wallpaper into `current.jpg` using an absolute `$FULL_PATH`. Change that one `ln -sf` invocation to `ln -sfr` (GNU `ln --relative`), keeping both operands (`"$FULL_PATH"` then `"$CURRENT_LINK"`) unchanged. Because both operands live under `$WALLPAPER_DIR` (`FULL_PATH="$WALLPAPER_DIR/$SELECTED"`, `CURRENT_LINK="$WALLPAPER_DIR/current.jpg"`), `-r` collapses the stored target to just the selected filename — matching Part A's relative form. The picker offers only maxdepth-1 files from the same directory, so a same-directory relative target is always correct.

Leave the cancel/restore path (the `if [[ -z "$SELECTED" ]]` block, lines ~110-119) unchanged: it only re-displays the previous wallpaper via `awww img "$PREVIOUS_WALLPAPER"` and never re-creates the symlink, so there is no absolute link to fix there — do NOT add a new `ln` call to it. Do NOT touch theme-engine/lib/generate.sh, theme-apply, or REQUIREMENTS.md — generate.sh's `readlink -f` already resolves relative targets against the symlink's directory, so no engine change is required.</action>
  <verify>
    <automated>test "$(readlink wallpapers/Pictures/Wallpapers/current.jpg)" = "shaded-landscape.jpg" && git add wallpapers/Pictures/Wallpapers/current.jpg && git ls-files -s wallpapers/Pictures/Wallpapers/current.jpg | grep -q '^120000 ' && test -f "$(readlink -f wallpapers/Pictures/Wallpapers/current.jpg)" && bash -n hypr/.config/hypr/scripts/wallpaper-picker.sh && shellcheck -S error hypr/.config/hypr/scripts/wallpaper-picker.sh && [ "$(grep -cE 'ln -s' hypr/.config/hypr/scripts/wallpaper-picker.sh)" -eq 1 ] && grep -qE 'ln -sf?r ' hypr/.config/hypr/scripts/wallpaper-picker.sh && echo PASS</automated>
  </verify>
  <done>`readlink current.jpg` prints `shaded-landscape.jpg` (no leading slash); `git ls-files -s` shows mode 120000 (still a symlink); the resolved target is a real file (`test -f` passes); `bash -n` and `shellcheck -S error` are clean on the picker; the picker has exactly one `ln -s` line and it uses relative form (`ln -sfr`). Output ends with PASS.</done>
</task>

</tasks>

<verification>
- `readlink wallpapers/Pictures/Wallpapers/current.jpg` prints `shaded-landscape.jpg` (relative, no leading slash)
- `git ls-files -s wallpapers/Pictures/Wallpapers/current.jpg` still shows mode 120000 (remains a symlink, not converted to a regular file)
- `test -f "$(readlink -f wallpapers/Pictures/Wallpapers/current.jpg)"` succeeds (resolved default wallpaper exists on disk)
- `bash -n` and `shellcheck -S error` are clean on hypr/.config/hypr/scripts/wallpaper-picker.sh
- The picker's only link-creation uses `ln -sfr` (or `ln -sf -r`) — grep confirms every current.jpg link creation is relative
</verification>

<success_criteria>
- The tracked `current.jpg` symlink points at a bare relative filename, so a fresh stow'd install resolves it to a real wallpaper and materialyou renders (INST-03 materialyou parity case passes) without any host-only state committed to the repo
- The wallpaper picker can never again re-write `current.jpg` to a host-absolute target
- Single atomic commit: `fix(03-01): make current.jpg wallpaper symlink relative (host-absolute path broke fresh-install materialyou)`
- Do NOT run the container-tier gate here — the orchestrator handles push + gate relaunch
</success_criteria>

<output>
Create `.planning/quick/260709-ciu-fix-host-absolute-wallpaper-symlink-brea/260709-ciu-SUMMARY.md` when done.
</output>
