---
phase: 17-ambient-extras
reviewed: 2026-08-10T11:05:00Z
depth: standard
files_reviewed: 23
files_reviewed_list:
  - .gitignore
  - hypr/.config/hypr/config/dynamic-cursors.lua
  - hypr/.config/hypr/config/env.lua
  - hypr/.config/hypr/config/permissions.lua
  - hypr/.config/hypr/hypridle.conf
  - hypr/.config/hypr/hyprland.lua
  - hypr/.config/hypr/scripts/gaming-mode-toggle.sh
  - hypr/.config/hypr/scripts/hyprpm-complete.sh
  - hypr/.config/hypr/scripts/quickshell-doctor
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-mpvpaper-layers.json
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-offlevel-mpvpaper-layers.json
  - hypr/.config/hypr/scripts/theme-init.sh
  - hypr/.config/hypr/scripts/wallpaper-picker.sh
  - hypr/.config/hypr/scripts/wallpaper-visibility.sh
  - install.sh
  - stow.sh
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/generate.sh
  - theme-engine/.config/theme-engine/lib/wallpaper.sh
  - theme-engine/.config/theme-engine/theme-apply
  - theme-engine/.config/theme-engine/theme-doctor
  - thunar/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
  - uwsm/.config/uwsm/env
findings:
  critical: 1
  warning: 5
  info: 2
  total: 8
status: issues_found
---

# Phase 17: Code Review Report

**Reviewed:** 2026-08-10T11:05:00Z
**Depth:** standard
**Files Reviewed:** 23
**Status:** issues_found

## Summary

Phase 17 (live wallpapers, hyprpm/dynamic-cursors, D-32 cursor pin) is unusually well-documented — every non-obvious decision carries an inline rationale, and the SUMMARY files record several bugs the plans themselves already found and fixed live (flock-fd inheritance deadlock, zombie-liveness false positives, SIGTERM-unresponsive WebP decode, the hover-vs-persisted-state render-gate bug). This review does not re-litigate any of those already-fixed issues, and does not re-flag the documented, deliberate choices listed in the task's `<known_deliberate_choices>` block (no `hl.plugin.load()` in `dynamic-cursors.lua`; both commented-out plugin-permission grants in `permissions.lua`; the `timeout`-bounded `hyprpm` calls; the zombie-excluding liveness checks in `wallpaper-visibility.sh`; the picker's "process survives a non-Esc exit" residual).

Tracing the actual data flow between `wallpaper-picker.sh`, `lib/wallpaper.sh`'s `theme_engine_wallpaper_sync_owner`, and `theme-apply` surfaced one real functional defect (CR-01) that none of the six plans' own verification passes appear to have exercised: a live wallpaper selected either via Ctrl-A cross-theme browsing or while the active mode is Material You never actually starts playback, silently downgrading to a static frame with a success notification that says otherwise. The remaining findings are narrower correctness/robustness gaps (a "desktop left unchanged" contract violation on a specific render-failure path, an un-stopped live player while browsing away to a still, a TOCTOU on the hover-settle write, orphaned temp files on a write failure, and an unsanitized value reaching `hyprctl eval`'s Lua-source argument) plus two informational nits.

## Critical Issues

### CR-01: A live wallpaper picked outside the "same static theme, in-theme" path never actually plays — silently downgrades to a static frame with a false-success notification

**File:** `hypr/.config/hypr/scripts/wallpaper-picker.sh:694-727`, `theme-engine/.config/theme-engine/lib/wallpaper.sh:343-388` (`theme_engine_wallpaper_sync_owner`), `theme-engine/.config/theme-engine/theme-apply:106`

**Issue:**

`theme_engine_wallpaper_sync_owner "$name" [ref]` only actually starts the live-wallpaper player when it receives an **explicit, non-empty `ref` argument** that is itself a valid `live/<file>` reference (`lib/wallpaper.sh:374-379`). When no second argument is supplied, it falls back to reading `$LAST_WALLPAPER_DIR/$name` (`lib/wallpaper.sh:370-372`) — a file that is populated **only** by `wallpaper-picker.sh`'s own writer-guard block at line 703-717, and **only** when the confirmed selection is inside the *current, active, static* theme's own folder (`"$SELECTED" == "$CURRENT_THEME/"*`).

Two reachable, undocumented, user-facing paths never populate that ref and therefore always resolve to `"$owner" clear` instead of `"$owner" select`:

1. **Ctrl-A cross-theme pick.** The header explicitly documents Ctrl-A as "temporarily browse the full collection" and a first-class feature (`wallpaper-picker.sh:13`). If the user confirms a `▶`-marked live entry that belongs to a *different* theme than the active one, `SELECTED` does not match `"$CURRENT_THEME/"*`, so the writer-guard block at line 703 is skipped entirely, `SYNC_REF` stays `""` (initialized at line 702), and `theme_engine_wallpaper_sync_owner "$CURRENT_THEME" ""` is called with an explicit-but-empty ref — which `sync_owner` treats as "nothing to remember" and issues `clear` (`lib/wallpaper.sh:374-379`). The live process never starts.
2. **Any live pick while the active mode is Material You.** For `materialyou`/`materialyou-light`, the picker takes a completely different branch (`wallpaper-picker.sh:694-696`) that calls `theme-apply "$CURRENT_THEME"` directly, without ever calling `sync_owner` itself. Inside `theme-apply`, `theme_engine_wallpaper_sync_owner "$NAME"` is called with **one** argument (`theme-apply:106`), so `have_ref=0` and `sync_owner` falls back to reading `$LAST_WALLPAPER_DIR/materialyou` — a file that is never written anywhere in this codebase (`theme_engine_wallpaper_autoset` returns immediately for both Material You names, `lib/wallpaper.sh:135-137`, and the picker's own writer-guard block is keyed to the same-theme-folder comparison that never applies under Material You). `ref` is therefore always empty and the owner always clears. This is reachable on every single live-wallpaper pick made while in Material You mode, not just a rare edge case — the picker's enumeration is unrestricted (`MODE_ARG="full"`) whenever `CURRENT_THEME` is a Material You name, so `▶` live entries are fully visible and selectable, and picking one silently never plays.

In both cases: `current.jpg` is correctly relinked to the extracted still frame (`wallpaper-picker.sh:662` / the frame produced before `theme-apply` runs), so the lock screen and (for Material You) the palette still get *something* reasonable — but the actual mpvpaper live playback the user selected never starts, `notify-send` still reports `"Wallpaper Changed" / "Set to $SELECTED"` (`wallpaper-picker.sh:698-700`) with no indication anything was downgraded, and if a *different* live wallpaper happened to already be playing, it is actively stopped and not replaced by anything. This directly contradicts AMB-01's core requirement (a picked live wallpaper plays) on two concretely reachable, keybind-documented paths, and none of the six plans' own coverage tables in the SUMMARY files exercise a cross-theme or Material-You live pick — every live-selection proof cited is an in-theme static pick.

**Fix:** Have the picker pass an explicit ref in both paths instead of relying on `sync_owner`'s no-ref fallback:

```bash
# wallpaper-picker.sh, static branch (~line 702) — pass the live ref even
# for a cross-theme pick, distinct from "nothing to remember":
SYNC_REF=""
if [[ "$SEL_IS_LIVE" == "1" ]]; then
    SYNC_REF="$FULL_PATH"   # sync_owner already accepts an absolute path form,
                             # or extend sync_owner to accept one directly
elif [[ -n "$CURRENT_THEME" && "$SELECTED" == "$CURRENT_THEME/"* ]]; then
    BARE_FILENAME="${SELECTED#"$CURRENT_THEME"/}"
    if [[ "$BARE_FILENAME" != */* ]] || theme_engine_wallpaper_is_live_ref "$BARE_FILENAME"; then
        ...
        SYNC_REF="$BARE_FILENAME"
    fi
fi
```

and for the Material You branch, call `theme_engine_wallpaper_sync_owner` (or the owner directly) with the explicit selection **before** or instead of relying on `theme-apply`'s own no-ref call, e.g. pass the picked ref through an env var or a second positional argument to `theme-apply` that it forwards to `sync_owner`. At minimum, until fixed, `notify-send` must not claim success when a live pick silently downgrades to a static frame.

## Warnings

### WR-01: `theme_engine_wallpaper_frame_repair` can mutate `current.jpg` before a render's success is known, contradicting the "Desktop left unchanged" error message

**File:** `theme-engine/.config/theme-engine/theme-apply:65-86`, `theme-engine/.config/theme-engine/lib/wallpaper.sh:301-324`

**Issue:** `theme_engine_wallpaper_frame_repair "$NAME"` runs unconditionally before `theme_engine_generate` (deliberately, per the inline comment, to protect Material You's palette source). For a *static* preset whose recorded `last-wallpaper/$NAME` names a live entry whose extracted frame is currently missing (e.g. `wallpaper-frames` was wiped), this call re-extracts the frame and immediately does `ln -sfr "$frame" "$WALLPAPER_DIR/current.jpg"` (`lib/wallpaper.sh:319-321`) — a real, persistent, disk-visible side effect (the lock screen reads `current.jpg` directly) — **before** `theme_engine_generate` has run at all. If `theme_engine_generate` subsequently fails, `theme-apply` prints `"Theme render failed. Desktop left unchanged."` and exits 1 (`theme-apply:73-86`) — but `current.jpg` has already been repointed at the *new* theme's frame. The next lock, or the next unrelated `theme-doctor`/render check, will show the switched-to theme's wallpaper even though the switch was reported as failed and "unchanged." This is narrow (requires a wiped `wallpaper-frames` directory plus a subsequent render failure) but is a real, reproducible contract violation, not merely cosmetic — a script's own explicit user-facing claim becomes false.

**Fix:** Either scope the repair guard to the theme that's *already* active (compare `$NAME` against `current-theme` before repointing `current.jpg`), or defer the `ln -sfr` until after `theme_engine_generate` succeeds while still running the extraction early (split "extract" from "repoint").

### WR-02: No code path stops the live wallpaper when browsing from a live entry to a still entry mid-picker-session

**File:** `hypr/.config/hypr/scripts/wallpaper-picker.sh:402-519` (`LIVE_SCRIPT`)

**Issue:** The picker's own header advertises "Desktop: live awww animated preview as you navigate through selections" (`wallpaper-picker.sh:9-10`). Once a live entry's hover survives the 0.25s debounce, `wallpaper-visibility.sh select` is called and mpvpaper starts a real, persistent background-layer player (`wallpaper-picker.sh:501-502`). If the user then navigates to a **still** entry, the `else` branch (`wallpaper-picker.sh:505-518`) only calls `awww img ...` — it never calls the owner's `clear`/`select` to stop the still-running mpvpaper process. The three only call sites that ever reach `wallpaper-visibility.sh` from this file are the startup `snapshot`, the live-hover settle block's `select`, and the exit-time `restore`/`sync_owner` calls — none of which fire on a mere still-hover mid-session. Since mpvpaper's background-layer surface is created after (and therefore very likely rendered above) `awww-daemon`'s own background-layer surface, the live video most likely keeps visibly covering the desktop while the user is looking at other, non-live previews, until Enter/Esc finally resolves it. This is a real, code-provable gap regardless of the exact compositor z-order: the picker's own advertised "live preview as you navigate" contract is violated the moment a live hover has ever settled in the session.

**Fix:** Have the still branch of `LIVE_SCRIPT` call `"$WALLPAPER_OWNER" clear` (best-effort, matching the existing `|| true` discipline) whenever a live selection could plausibly be active, or track "was a live entry ever settled this session" and stop it explicitly before repainting a still preview.

### WR-03: Hover settle block repoints `current.jpg` before the owner's own `select` revalidates the file still exists (TOCTOU)

**File:** `hypr/.config/hypr/scripts/wallpaper-picker.sh:470-502`

**Issue:** The settle block extracts/relinks `current.jpg` to the hovered live entry's frame (line 475) and records `last-wallpaper/<theme>` (lines 490-494) **before** calling `"$WALLPAPER_OWNER" select "$FILE"` (line 501-502), which is where the owner's own `_validate_selection` re-checks that the file still exists and still resolves correctly (`wallpaper-visibility.sh:198-217`). If the underlying source file is deleted in the window between the settle block's own `[[ ! -f "$FILE" ]]` check (line 435, evaluated at hover time, not at settle time) and the `select` call actually running, `current.jpg` and `last-wallpaper` end up pointing at a frame for a video that the owner rejected and never plays — a state neither "the previous selection" nor "the new selection," with no player actually running behind it. Narrow, but the fix is cheap since the owner already re-validates.

**Fix:** Only relink `current.jpg`/write `last-wallpaper` after confirming the owner's `select` call succeeded (check its exit code), or re-check `[[ -f "$FILE" ]]` immediately before the relink.

### WR-04: `_write_intent`/`_write_selection`/`_write_actuated`/`_write_snapshot` can leak an orphaned temp file on a write failure

**File:** `hypr/.config/hypr/scripts/wallpaper-visibility.sh:146-181`

**Issue:** Each of these follows the pattern `tmp="$(mktemp ...)"; printf '%s\n' "$value" >"$tmp" && mv -f "$tmp" "$dest"`. If the `printf` redirect fails (disk full, permissions), the `&&` short-circuits and `mv` never runs — but the `mktemp`-created file is never cleaned up. Under `set -euo pipefail`, this doesn't abort the containing verb (the `&&` chain itself isn't a bare failing command at the top level of a `_write_*` function's return value — the function keeps returning whatever `mv`'s absence yields, i.e., the `&&` expression's own nonzero status, which callers generally don't check), so this silently leaves a stray `.$source.XXXXXX`-style file behind in `$INTENT_DIR` on every failed write. Low impact (rare failure mode, small files) but a real robustness gap in an owner script that already goes to considerable lengths for atomicity elsewhere.

**Fix:** `tmp="$(mktemp ...)"; { printf '%s\n' "$value" >"$tmp" && mv -f "$tmp" "$dest"; } || rm -f "$tmp"`.

### WR-05: Unsanitized value spliced directly into a `hyprctl eval` Lua-source string

**File:** `hypr/.config/hypr/scripts/gaming-mode-toggle.sh:183-212` (pre-existing 13.1-era code, two new sibling call sites added by 17-03 do not touch this section)

**Issue:** `gaming_mode_off()`'s restore path builds live Lua source by direct string interpolation: `hyprctl eval "hl.config({ decoration = { blur = { enabled = $v } } })"`, where `$v` comes from `_restore_keyword`, which reads a value out of `~/.local/state/theme/hyprland-tokens.lua` via `contract_extract_values`. The file's own comment states this is currently "provably dead code" because no `decoration:*`/`animations:*` key exists in the merged token table on this repo's layout, so `$v` is always empty today. That said, the code path is real and reachable the moment any future contributor's change happens to add such a key with a value that isn't a bare `true`/`false` token (e.g. a string containing `})` or a stray Lua expression) — at that point this becomes genuine Lua-source injection into the live compositor's `hyprctl eval` channel, since nothing here validates `$v`'s shape before splicing it into the eval string (unlike, e.g., `theme_engine_wallpaper_frame_offset`'s careful regex+range validation of a comparable operator-facing value elsewhere in this phase). This is defense-in-depth, not an active exploit today, but it's the one place in the reviewed diff where a value reaches a code-evaluation sink without a shape check.

**Fix:** Validate `$v` against `^(true|false)$` before splicing it into the `hl.config({...})` string, falling back to `need_reload=1` (the existing safe default) on anything else.

## Info

### IN-01: `theme-init.sh` lacks `set -euo pipefail`, unlike its sibling entrypoints

**File:** `hypr/.config/hypr/scripts/theme-init.sh:1-37`

**Issue:** `theme-apply` and `wallpaper-visibility.sh` both open with `set -euo pipefail`; `theme-init.sh` (the login entrypoint that calls both) has no such guard. A failing `cat`, `awww img`, or the backgrounded `hyprpm-complete.sh` line would silently continue rather than surface. Given this script's own contract is "thin caller, never blocks," this is likely intentional best-effort behavior rather than an oversight, but it's an inconsistency worth a second look given every other script this phase touches is disciplined about it.

**Fix:** Add `set -euo pipefail` if failures here should be visible, or leave a comment explaining the deliberate omission if this is intentional best-effort design.

### IN-02: `wallpaper-visibility.sh select`'s usage text claims "requires an absolute path" but does not enforce it

**File:** `hypr/.config/hypr/scripts/wallpaper-visibility.sh:390-405`

**Issue:** `_cmd_select`'s error message says `'select' requires an absolute path`, but the implementation only checks non-emptiness before handing the raw value to `_validate_selection`, which resolves it via `realpath -m` (works fine against a relative path, resolved against the caller's CWD) and only rejects it if the *normalized* result doesn't land under `$WALLPAPERS_ROOT/*/live/`. A relative path can therefore succeed or fail depending on the caller's CWD at invocation time, which the docstring doesn't describe.

**Fix:** Either enforce `[[ "$raw" == /* ]]` explicitly to match the documented contract, or update the usage/doc text to describe the actual (CWD-relative-then-normalized) behavior.

---

_Reviewed: 2026-08-10T11:05:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
