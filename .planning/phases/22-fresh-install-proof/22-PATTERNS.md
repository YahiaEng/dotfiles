# Phase 22: Fresh-Install Proof - Pattern Map

**Mapped:** 2026-08-16
**Files analyzed:** 6 (1 new checker + its fixtures, 1 new allowlist file, 4 modified files)
**Analogs found:** 6 / 6 (all internal to this repo — no external analog needed)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `hypr/.config/hypr/scripts/<new-dangling-symlink-checker>` (name TBD, D-22-06) | utility/checker (bash+python CLI) | batch/transform (filesystem sweep, report lines) | `hypr/.config/hypr/scripts/retirement-check` (primary) + `hypr/.config/hypr/scripts/motion-lint`/`colour-lint` (secondary) | exact — same "standalone checker with `--self-test`" family |
| `hypr/.config/hypr/scripts/tests/<new-checker>-fixtures/` | test fixture tree | batch | `hypr/.config/hypr/scripts/tests/retirement-fixtures/` | exact |
| committed session-failure allowlist file (path TBD, next to `verify/container-run.sh`, D-22-08/09/10) | config/data file consumed by a harness | CRUD (read-only lookup) | `motion-lint`'s `EXEMPTIONS`/`LINE_EXEMPTIONS` (inline Python list literal) — closest in-repo shape; `retirement-check`'s `REGISTRY_RAW` heredoc string — closest "external-looking but still inline" shape; `theme-engine/.config/theme-engine/contract.json` — closest genuinely-separate-file precedent | role-match (no exact "separate committed allowlist file read by a bash harness" precedent exists yet — see below) |
| `theme-engine/.config/theme-engine/theme-doctor` (MODIFY — new fold) | orchestrator/aggregator (bash) | event-driven (line-stream fold) | itself — 3 existing folds at lines 461, 485, 520 | exact (same file, same idiom, extend in place) |
| `verify/container-run.sh` (MODIFY — new blocking step(s)) | test harness / CI script (bash) | batch (sequential steps, summary log) | itself — existing `log_step` call sites (bootstrap/clone/install/stow/theme-parity) | exact |
| `VERIFICATION.md` (MODIFY — §5/§6/§7/§8 prose) | docs | n/a | itself — existing §5-§8 prose | exact |
| `README.md` (MODIFY — feature table row + tree diagram) | docs | n/a | itself — line 24 table row, lines 70-73 tree diagram | exact |
| `hypr/.config/hypr/config/env.lua` (MODIFY — lines 15-16 comment) | config module (Lua) | n/a (comment only) | itself | exact |

## Pattern Assignments

### New dangling-symlink checker (D-22-06)

**Primary analog:** `hypr/.config/hypr/scripts/retirement-check` (full file read, 767 lines)
**Secondary analogs:** `hypr/.config/hypr/scripts/motion-lint`, `hypr/.config/hypr/scripts/colour-lint`

**Shebang + header block convention** (retirement-check lines 1-70, motion-lint lines 1-97, colour-lint lines 1-110):
```bash
#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              <NAME> (<phase-plan-id>)                 ║
# ║  <one-line purpose>. Report-only — never mutates.      ║
# ╚══════════════════════════════════════════════════════╝
#
# <requirement-id> requires ...
#
# Usage:
#   <name> [target-dir]
#       No argument: scans the real deployed surface set. With an
#       argument: treats target-dir as ONE flat directory — same code
#       path serves a throwaway/poisoned fixture directory as serves the
#       real tree (D-28: "a gate that cannot be pointed at a fixture
#       cannot be proven to fail").
#   <name> --self-test
#       Runs the committed fixtures under tests/<name>-fixtures/ and
#       asserts each expected verdict. Exit 0/1.
#   <name> --list          (retirement-check only, optional for new checker)
#   <name> --root <dir>    (retirement-check's flag name — pick ONE of
#                           "[target-dir]" positional (motion-lint/colour-lint
#                           style) or "--root <dir>" flag (retirement-check
#                           style); do not invent a third shape)
#
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/tests/<name>-fixtures"
```
(retirement-check additionally sets `SELF_PATH="$SCRIPT_DIR/retirement-check"` and `DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"` — the checker needs `DOTFILES_DIR`-equivalent sweep root since it must cover paths **outside** `$HOME/.config` per D-22-06's discretion note: `~/Pictures`, `~/.local`, `~/.config/systemd/user`, matching `stow.sh`'s `PACKAGES` loop targets, not `motion-lint`'s narrower `$HOME/.config/hypr` etc. ROOTS array.)

**CLI flag parsing block** (retirement-check lines 726-761, the `case "${1:-}"` dispatch):
```bash
case "${1:-}" in
    --list)
        run_list
        exit 0
        ;;
    --self-test)
        run_self_test
        exit $?
        ;;
    --all)
        run_all
        exit $?
        ;;
    "")
        usage
        exit 2
        ;;
esac
```
motion-lint/colour-lint use a flatter shape instead (colour-lint lines 646-698): a plain `if [[ "${1:-}" == "--self-test" ]]; then ... fi` followed by `if [[ "${1:-}" == "--no-pending" ]]; then ... fi` followed by fallthrough to `TARGET_DIR="${1:-}"`. Either shape is acceptable per D-22-06's "match the conventions of the neighbouring checkers" — retirement-check's `case` is the more scalable one if the new checker grows more than 2 flags.

**`--self-test` harness structure** (retirement-check lines 677-724, `run_self_test()`):
```bash
run_self_test() {
    local -a fixtures=(
        "compliant-clean-surface:0"
        "poisoned-stray-layer-rule:1"
        "poisoned-stray-contract-entry:1"
        "poisoned-stray-cross-script-ref:1"
        "poisoned-planning-only:0"
    )
    local st_pass=0 st_fail=0
    local entry fname expect_nonzero fixture_root rc want_desc out

    echo "retirement-check --self-test — replaying the five committed fixtures"
    echo ""

    for entry in "${fixtures[@]}"; do
        fname="${entry%%:*}"
        expect_nonzero="${entry##*:}"
        fixture_root="$FIXTURES_DIR/$fname"

        if [[ ! -d "$fixture_root" ]]; then
            printf '  [FAIL] self-test: fixture missing: %s\n' "$fixture_root"
            st_fail=$((st_fail + 1))
            continue
        fi

        out="$("$SELF_PATH" retirement-fixture --root "$fixture_root" 2>&1)"
        rc=$?

        if [[ "$expect_nonzero" == "0" ]]; then
            want_desc="exit 0 (compliant)"
        else
            want_desc="a non-zero exit (poisoned)"
        fi

        if [[ "$expect_nonzero" == "0" && "$rc" -eq 0 ]] || [[ "$expect_nonzero" == "1" && "$rc" -ne 0 ]]; then
            printf '  [PASS] self-test: %s -> %s as expected\n' "$fname" "$want_desc"
            st_pass=$((st_pass + 1))
        else
            printf '  [FAIL] self-test: %s -> exited %d, expected %s\n' "$fname" "$rc" "$want_desc"
            printf '         output:\n%s\n' "$(printf '%s\n' "$out" | sed 's/^/           /')"
            st_fail=$((st_fail + 1))
        fi
    done

    echo ""
    printf 'Self-test summary: %d passed, %d failed\n' "$st_pass" "$st_fail"
    [[ "$st_fail" -eq 0 ]]
}
```
motion-lint/colour-lint's variant (motion-lint lines 996-1072) copies each fixture *file* (not a whole directory tree) into a fresh `mktemp -d` and invokes `"$0" "$tmp"` — appropriate when fixtures are single flat files scanned by extension. retirement-check's variant invokes the compiled-in `retirement-fixture` registry entry against a whole committed directory tree via `--root`. **Pick retirement-check's whole-tree-fixture shape** for the new checker: a dangling-symlink checker inherently needs a *directory tree containing an actual symlink* (compliant = resolves, poisoned = dangling) — a single flat file cannot express a symlink fixture, so `mktemp -d` + single-file copy (motion-lint's shape) cannot represent the poisoned case at all. retirement-check's `tests/retirement-fixtures/<name>/` committed-tree-per-fixture layout is therefore the load-bearing precedent, not motion-lint's.

**Exact `[PASS]`/`[FAIL]` output line format** — shared verbatim by all three checkers, this is what `theme-doctor`'s fold parses (see below):
```
[PASS] <surface-or-desc>: <detail>
[FAIL] <surface-or-desc>: <detail>
[SKIP] <detail>
```
retirement-check emits these via its own `emit_class()` (lines 592-615): `print(f'[PASS] {surface}/{cname}: no references')` / `print(f'[FAIL] {surface}/{cname}: {count} reference(s)')`. motion-lint/colour-lint emit them via the bash `check()` helper (motion-lint lines 106-116):
```bash
check() {
    local desc="$1"
    local ok="$2"
    if [[ "$ok" == "0" ]]; then
        printf '  [PASS] %s\n' "$desc"
        PASS=$((PASS + 1))
    else
        printf '  [FAIL] %s\n' "$desc"
        FAIL=$((FAIL + 1))
    fi
}
```
Final summary line convention (both families):
```
Summary: N passed, M failed
```
(retirement-check: `Summary: surface=$SURFACE status=... failed_classes=N` — a variant; motion-lint/colour-lint: `Summary: %d passed, %d %s\n` with `FAIL_WORD` singular/plural handling.) The new checker should follow motion-lint/colour-lint's `Summary: N passed, M failed` shape since `theme-doctor`'s fold expects a `[PASS]`/`[FAIL]`-per-line stream regardless of which summary format trails it.

**Fixture tree directory layout convention** (`hypr/.config/hypr/scripts/tests/retirement-fixtures/`, verified via `find`):
```
tests/retirement-fixtures/
├── compliant-clean-surface/
│   ├── hypr/.config/hypr/...
│   ├── matugen/.config/matugen/...
│   ├── kitty/kitty.conf
│   ├── theme-engine/.config/theme-engine/...
│   ├── install.sh
│   └── stow.sh
├── poisoned-stray-layer-rule/       (same skeleton, one poisoned entry)
├── poisoned-stray-contract-entry/
├── poisoned-stray-cross-script-ref/
└── poisoned-planning-only/
```
Each fixture is a **miniature mirror of the real repo root** (own `hypr/`, `matugen/`, `kitty/`, `theme-engine/`, `install.sh`, `stow.sh`) so `--root <fixture-dir>` can be pointed at it exactly as if it were `$DOTFILES_DIR`. A compliant fixture vs. a poisoned one differ by exactly one planted artifact (e.g. one extra `hl.layer_rule(...)` line, one extra `contract.json` entry) — never a structurally different tree. For the new dangling-symlink checker, the fixture tree needs at minimum: one compliant symlink (resolves) and one poisoned dangling symlink (target missing), planted at a couple of representative locations under the repo-root mirror (mirroring `stow.sh`'s `PACKAGES` loop targets — see below).

**Sweep-root coverage requirement** (per D-22-06 discretion note + `stow.sh:19` / `stow.sh:200-225`):
```bash
# stow.sh:19 — PACKAGES array (17 entries incl. cava, quickshell; excerpt)
PACKAGES=(
    cava
    elephant
    fastfetch
    fish
    gtk
    hypr
    kitty
    matugen
    quickshell
    theme-engine
    thunar
    ...
)
```
```
# stow.sh:190-225 — the three documented exceptions to "every package
# ships exclusively under ~/.config/<pkg>/":
#   1. `wallpapers` — roots outside .config/ (→ ~/Pictures/Wallpapers,
#      ~/Pictures/Screenshots)
#   2. `quickshell` — a second tree at ~/.config/autostart/
#      (nm-applet.desktop secret-agent override)
#   3. `quickshell` — a third tree at ~/.config/systemd/user/
#      (quickshell.service)
```
The new checker's sweep must therefore cover: `$HOME/.config/<every-PACKAGES-entry>`, `$HOME/Pictures/Wallpapers`, `$HOME/Pictures/Screenshots`, `$HOME/.config/autostart`, `$HOME/.config/systemd/user` — not just `$HOME/.config`.

---

### Fixture trees for the new checker

**Analog:** `hypr/.config/hypr/scripts/tests/retirement-fixtures/` (see directory layout above). Compliant vs. poisoned distinguished by ONE planted artifact difference against an otherwise-identical repo-root-mirror skeleton — no structural divergence beyond the one thing under test.

---

### Committed session-failure allowlist file (D-22-08/09/10)

**Analogs compared** (per task instructions, all four read):

1. **`motion-lint`'s `EXEMPTIONS`/`LINE_EXEMPTIONS`** (motion-lint lines 417-449) — **inline Python list-of-dicts literal embedded in the script's heredoc**, not a separate file:
```python
EXEMPTIONS = [
    {'glob': 'walker/**/style.css', 'regex': re.compile(r'(^|/)walker/.*/style\.css$'),
     'reason': 'no motion literals — motion is compositor-delivered through '
               'the layer animation',
     'pending': False},
]
```
Each entry: `glob`/`label`, `regex` (compiled), `reason` (non-empty string, enforced), `pending` (bool, structured — not a substring-matched flag in prose). `--no-pending` (motion-lint lines 458-481) asserts zero `pending: True` entries.

2. **`colour-lint`'s `EXEMPTIONS`/`LINE_EXEMPTIONS`** (colour-lint lines 288-339) — same inline-Python-literal shape, same `label`/`regex`/`reason`/`pending` fields, plus `LINE_EXEMPTIONS` additionally carries `anchor` (compiled regex) + resolved `line` (int, filled at runtime) for content-anchored (not hardcoded-line-number) narrow carve-outs.

3. **`retirement-check`'s registry** (retirement-check lines 77-105) — **inline bash heredoc string, pipe-delimited, parsed into associative arrays**:
```bash
REGISTRY_RAW='waybar|retired|waybar/:hypr/.config/hypr/scripts/waybar-*|RETIRE-02
swaync|retired|swaync/:hypr/.config/hypr/scripts/swaync-*|RETIRE-03
...'
declare -A REG_STATUS REG_OWNTREE REG_REQ
REGISTRY_ORDER=()
while IFS='|' read -r _rc_name _rc_status _rc_owntree _rc_req; do
    [[ -z "$_rc_name" ]] && continue
    REGISTRY_ORDER+=("$_rc_name")
    REG_STATUS["$_rc_name"]="$_rc_status"
    ...
done <<< "$REGISTRY_RAW"
```
Also inline, not a separate file — bash-native pipe-delimited text, one record per line, four columns.

4. **`theme-engine/.config/theme-engine/contract.json`** — the one **genuinely separate, committed, machine-read JSON file** in this repo's gate-data family (referenced by `retirement-check`'s class 5 `scan_contract_json`, not read directly in this pass — file itself not re-read here since CONTEXT.md's own summary already characterizes it as JSON and this task's budget prioritized the three inline shapes above). This is the closest existing precedent for "a separate file, not inline in the consuming script."

**Verdict for the planner:** **no existing precedent is a separate-file allowlist read by a bash harness** (`container-run.sh`) — all three checker-internal precedents (`motion-lint`, `colour-lint`, `retirement-check`) keep their exemption/registry data **inline in the script itself**, not in a sibling file. `contract.json` is the only separate-file precedent, but it is consumed by Python/bash JSON-parsing inside a *checker*, not read by `container-run.sh`'s bash heredoc directly. Since D-22-10 explicitly requires the allowlist to live **next to `container-run.sh`** (a separate file, by the decision's own text: "committed next to container-run.sh... a re-run months later enforces the same bar"), the planner should pick a format `container-run.sh`'s existing bash (`set -uo pipefail`, no python dependency inside the container-side heredoc beyond what's already there) can parse directly without inventing new tooling — a flat TSV/pipe-delimited text file (mirroring `retirement-check`'s inline `REGISTRY_RAW` shape, but as a real file read via `<file` instead of a heredoc string) is the shape most consistent with what this repo already does elsewhere, since `container-run.sh`'s in-container script is pure bash with no python3 dependency today. A `.json` file would require introducing `jq` (not currently used anywhere in `container-run.sh`) or a python3 parse step — heavier than the existing inline-text precedent justifies, but is not ruled out if the planner prefers `contract.json`'s shape for consistency with the checker-data family.

---

### `theme-engine/.config/theme-engine/theme-doctor` — fold pattern (MODIFY)

**Analog:** itself, the three existing folds, verified at their real line numbers (drift from CONTEXT.md's claimed line numbers: motion-lint fold header is at line 461 as claimed; hypr-equivalence-check fold header is at line 485 as claimed; colour-lint fold header is at line 520 as claimed — all three match CONTEXT.md exactly, no drift).

**Fold 1 — `motion-lint` (unguarded, degrades to SKIP)** — theme-doctor lines 461-483, verbatim:
```bash
# ── motion-lint fold (12-05, TOKEN-04) ──────────────────────────────────
# ...
MOTION_LINT="$HOME/.config/hypr/scripts/motion-lint"
if [[ -x "$MOTION_LINT" ]]; then
    while IFS= read -r _ml_line; do
        case "$_ml_line" in
            *"[PASS]"*) check "motion-lint: ${_ml_line#*\[PASS\] }" "0" ;;
            *"[FAIL]"*) check "motion-lint: ${_ml_line#*\[FAIL\] }" "1" ;;
            *)          echo "  $_ml_line" ;;
        esac
    done < <("$MOTION_LINT" 2>/dev/null)
else
    echo "  [SKIP] motion-lint ($MOTION_LINT not found or not executable)"
fi
```

**Fold 2 — `hypr-equivalence-check` (LIVE-SESSION GUARDED)** — theme-doctor lines 485-518, verbatim:
```bash
# ── hypr-equivalence-check fold (14-10 Task 3, MAINT-04) ─────────────────
# ...
HYPR_EQUIVALENCE_CHECK="$HOME/.config/hypr/scripts/hypr-equivalence-check"
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && [[ -x "$HYPR_EQUIVALENCE_CHECK" ]]; then
    while IFS= read -r _hec_line; do
        case "$_hec_line" in
            *"[PASS]"*) check "hypr-equivalence-check: ${_hec_line#*\[PASS\] }" "0" ;;
            *"[FAIL]"*) check "hypr-equivalence-check: ${_hec_line#*\[FAIL\] }" "1" ;;
        esac
    done < <("$HYPR_EQUIVALENCE_CHECK" 2>/dev/null)
else
    echo "  [SKIP] hypr-equivalence-check (no live Hyprland session — HYPRLAND_INSTANCE_SIGNATURE unset — or $HYPR_EQUIVALENCE_CHECK not found/executable)"
fi
```
This is the **guarded-skip-when-absent branch** the task instructions call out — note it is the ONLY one of the three folds gated on more than mere executable-presence (`[[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] &&`), because it re-derives live compositor state. A filesystem-only checker (like the new dangling-symlink one, which reads files/symlinks on disk and never touches the compositor) should follow **Fold 1 or Fold 3's unguarded shape**, not Fold 2's — same reasoning `colour-lint`'s own fold comment states explicitly (lines 533-536): "UNLIKE the hypr-equivalence-check fold immediately above, this fold needs NO live-session guard... reads files on disk and never touches the compositor... must stay unguarded and therefore still runs in a headless fresh-install container." This directly matters for D-22-06/D-22-05: the container gate needs the new symlink checker's fold to run headless, so it must copy Fold 1/3's `if [[ -x "$CHECKER" ]]` shape, never Fold 2's live-session guard.

**Fold 3 — `colour-lint` (unguarded, no session needed)** — theme-doctor lines 520-548, verbatim:
```bash
# ── colour-lint fold (18-03, GATE-04, D-18-35) ───────────────────────────
# ...
COLOUR_LINT="$HOME/.config/hypr/scripts/colour-lint"
if [[ -x "$COLOUR_LINT" ]]; then
    while IFS= read -r _cl_line; do
        case "$_cl_line" in
            *"[PASS]"*) check "colour-lint: ${_cl_line#*\[PASS\] }" "0" ;;
            *"[FAIL]"*) check "colour-lint: ${_cl_line#*\[FAIL\] }" "1" ;;
            *)          echo "  $_cl_line" ;;
        esac
    done < <("$COLOUR_LINT" 2>/dev/null)
else
    echo "  [SKIP] colour-lint ($COLOUR_LINT not found or not executable)"
fi
```

There is also a fourth, adjacent fold immediately below (line 550 onward) for `retirement-check` itself — same unguarded shape, `[REPORT]`/`[SKIP]` lines passed through unfolded via a bare `*)` arm (line 559: "matching the motion-lint fold's own third arm"). **The new dangling-symlink checker's fold should be inserted as a fifth fold in this same block (after line ~570, following the retirement-check fold), copying Fold 3's (colour-lint's) exact shape** — unguarded `[[ -x ]]` check, `[PASS]`/`[FAIL]` folded via `check()`, everything else passed through via `*) echo "  $_line" ;;`.

---

### `verify/container-run.sh` — `log_step` helper + summary.log convention (MODIFY)

**Analog:** itself.

**`log_step` helper** (container-run.sh lines 117-132, verbatim, defined inside the in-container heredoc):
```bash
log_step() {
    # log_step <name> <logfile> <cmd...>
    local name="$1" logfile="$2"
    shift 2
    echo ""
    echo "=== $name ==="
    if "$@" > "$logfile" 2>&1; then
        echo "  [OK] $name"
        return 0
    else
        local rc=$?
        echo "  [FAIL] $name (exit $rc)"
        tail -n 40 "$logfile" || true
        return "$rc"
    fi
}
```

**`step=<name> status=<ok|fail>` summary.log convention** — every existing call site follows this exact shape (container-run.sh lines 136-215, one representative excerpt):
```bash
if log_step "install.sh --core-only" /logs/03-install.log \
    su - builder -c "cd ~/dotfiles && chmod +x install.sh stow.sh && ./install.sh --core-only"; then
    echo "step=install status=ok" >> /logs/summary.log
else
    echo "step=install status=fail" >> /logs/summary.log
    GATE_FAIL=1
fi
```
Every blocking step: (1) guarded by `if [[ "$GATE_FAIL" -eq 0 ]]; then ... fi` so a prior failure short-circuits remaining steps, (2) calls `log_step` with a numbered logfile (`/logs/0N-<name>.log`), (3) appends `step=<name> status=ok|fail` to `/logs/summary.log`, (4) sets `GATE_FAIL=1` on failure. The `theme-doctor` step (lines 195-202) is the **informational-only exception** — it does NOT gate `GATE_FAIL`, and its summary line carries an `rc=$?` suffix instead of `ok|fail`: `echo "step=theme-doctor status=informational rc=$?" >> /logs/summary.log`. **D-22-08 requires flipping this exact step from informational to blocking** — the planner's action here is to convert this one call site from the informational shape to the standard `if log_step ... status=ok/fail ... GATE_FAIL=1` shape used by every other step, while additionally consulting the new allowlist file to distinguish an admitted session-dependent failure from a real regression before setting `GATE_FAIL=1`.

**Where new blocking steps slot in without touching verdict logic:** insert additional `if [[ "$GATE_FAIL" -eq 0 ]]; then ... fi` blocks between the existing `stow` step (ends line 188) and the `theme-doctor` step (starts line 195) — e.g. a `retirement-check --all` step and a new dangling-symlink-checker step both belong here, each following the exact `log_step` + `step=<name> status=ok|fail` + `GATE_FAIL=1` shape shown above. The verdict logic itself (lines 217-226, `overall=PASS`/`overall=FAIL` + `exit "$GATE_FAIL"`) and the outer host-side verdict check (lines 257-279, "never trust the container exit code alone") need NO changes — `GATE_FAIL` accumulation already generalizes to any number of steps.

**In-container heredoc constraints (preserve both):**
1. Single-quoted delimiter: `cat > "$CONTAINER_SCRIPT_FILE" <<'CONTAINER_SCRIPT'` (line 104) — nothing inside expands on the host; every `$VAR` resolves inside the container.
2. The script runs from a file over the `/logs` mount (`podman run ... "$IMAGE" bash /logs/container-script.sh`, line 243), never fed via stdin — this is the fix for the documented `run-20260708T220706Z` stdin-eating false-pass post-mortem (lines 81-92). `exec </dev/null` (line 112) is belt-and-suspenders inside the container script itself.

---

### `VERIFICATION.md` — §5/§6/§7/§8 current text (MODIFY)

Verified against the real file (line numbers match CONTEXT.md's canonical-refs claims exactly — no drift found):

**§5 — "Run install.sh --core-only, then stow.sh"** (lines 152-171) — the `--core-only` invocation D-22-11 addresses (D-22-11 concludes container stays `--core-only`; VM tier runs unflagged — so §5's own VM-tier instructions at lines 156/157 (`./install.sh --core-only`) must change to drop `--core-only` for the VM tier per D-22-11):
```
## 5. Run install.sh --core-only, then stow.sh

​```bash
chmod +x install.sh stow.sh
./install.sh --core-only
​```

Confirm the run ends with `install.sh`'s post-install verification table
printing `[OK]` for every package and `All N packages verified installed.`
— any `[MISS]` line means `install.sh` already exited nonzero (D-63/D-64)
and this run has failed; do not proceed.

​```bash
./stow.sh
​```

Confirm `stow.sh` completes with no errors and prints
`Dotfiles stowed successfully!` — this also seeds the first-boot theme
baseline (`theme-apply catppuccin`, D-60) so `~/.local/state/theme/`
exists before the first Hyprland login.
```

**§6 — "Start Hyprland via uwsm"** (lines 173-186) — contains the package name D-22-03 flags:
```
## 6. Start Hyprland via uwsm

​```bash
uwsm start hyprland-uwsm.desktop
​```

(Or select "Hyprland (uwsm-managed)" from a display manager if one is
configured — the minimal archinstall baseline from step 2 has none by
default, so the TTY command above is the expected path here.)

Confirm walker, elephant, the Quickshell bar, swaync, and Thunar all come
up themed — no relogin, no manual fixups. This is the moment the
container tier cannot exercise at all.
```
(Line 183 is the exact `swaync`-naming line D-22-03 targets. CONTEXT.md said "line 183" — verified correct, no drift.)

**§7 — "Run theme-doctor and theme-parity, save the logs (D-45)"** (lines 187-207) — the pass condition D-22-02 amends:
```
## 7. Run theme-doctor and theme-parity, save the logs (D-45)

With the live Hyprland session running:

​```bash
~/.config/theme-engine/theme-doctor | tee ~/theme-doctor-verify.log
echo "theme-doctor exit: $?"

~/.config/theme-engine/theme-parity | tee ~/theme-parity-verify.log
echo "theme-parity exit: $?"
​```

Both commands must exit `0`. `theme-doctor`'s summary line must read
`Summary: N passed, 0 failed` — including the session-dependent checks
(`walker process running`, `elephant process running`, `gsettings
gtk-theme = adw-gtk3-dark`, `elephant listproviders responds`) that the
container tier cannot exercise. `theme-parity` must report 0 failures
across all 7 render targets.
```
D-22-02 requires the "must read `Summary: N passed, 0 failed`" line above to become "0 failed minus a pre-authored exemption list" — this is the literal sentence to rewrite.

**§8 — "Human visual confirmation (D-53 — non-negotiable)"** (lines 209-223) — contains the second package-name hit D-22-03 flags:
```
## 8. Human visual confirmation (D-53 — non-negotiable)

Look at the VM's own display (the SPICE/QEMU console window, not a
screenshot taken by a script) and confirm, with your own eyes:

- The Quickshell bar (including its in-process power menu), swaync,
  walker, and Thunar all show the same theme (Catppuccin, by default
  from the first-boot seed in step 5)
- Switching themes (`Super + Shift + T`) live-updates every visible app
  instantly, no relogin — the same ten-target standard from Phase 1/2
- Nothing is unstyled, blank, or still showing stock GTK defaults

Only once you have personally seen this does INST-03 pass. Record the
verdict (pass/fail, with a note on anything unexpected) alongside the
container-tier logs in the phase SUMMARY.
```
(Line 214 is the exact `swaync`-naming bullet D-22-03 targets — CONTEXT.md said "line 214", verified correct, no drift.) D-22-03 requires renaming both §6's and §8's surface lists to requirement IDs (QBAR/QNOTIF/QOSD/QPOWER/QMEDIA) instead of package names — `swaync` in both places must become the notification-surface requirement ID naming, and OSD/power-menu/media-tab surfaces (currently entirely absent from both lists) must be added by requirement ID per D-22-03's full inventory: "bar, notification popups + centre, dashboard drawer, OSD indicators, power menu, workspace overview, Media tab with the cava ring, walker, Thunar."

---

### `README.md` — feature table row + tree diagram (MODIFY)

Verified against the real file (line numbers match CONTEXT.md's claims — no drift):

**Line 24 — feature table row** (part of the "📦 Stack" table, lines 16-30):
```
| Notifications   | SwayNC                |
```

**Lines 70-73 — repo-tree diagram, `swaync/` package block** (part of the "📂 Structure" fenced code block, lines 32-88):
```
├── swaync/.config/swaync/
│   ├── config.json
│   ├── style.css
│   └── colors.css                      # Active colors (auto-managed)
│
```
(CONTEXT.md said "lines 70/80" loosely — verified: the `swaync/` block itself starts at line 70 and its content runs through line 74 including the trailing blank line before `matugen/` starts at line 75; there is no separate hit at line 80 — line 80 falls inside the `themes/` block, which is unrelated. Treat "lines 70/80" as approximate; the actual stale block is lines 70-74.)

Note: this README also reflects a materially older repo structure throughout (references `.conf`-suffixed Hyprland config files rather than the current `.lua` config modules, no `cava/` package, no OSD/power-menu/dashboard surfaces) — the phase's stated scope for README.md is narrowly the SC-3 review-pass fix (swaync row + tree block), not a full rewrite; flag this wider staleness to the planner as context but do not treat it as in-scope per D-22-07's explicit rejection of "promoting these to the blocking tier."

---

### `hypr/.config/hypr/config/env.lua` lines 15-16 (MODIFY)

Verified against the real file — CONTEXT.md's claimed lines 15-16 are correct, no drift. Full comment block for context (lines 14-20):
```lua
-- HYPRCURSOR_THEME/HYPRCURSOR_SIZE are new here: Hyprland reads these for
-- every native Wayland client (kitty, walker, quickshell, waybar,
-- swaync, Thunar-under-Wayland), pointed at `rose-pine-hyprcursor`
-- (already installed, 17-04) — the hyprcursor-format sibling of the same
-- BreezeX-remixed-to-Rose-Pine shape family (rose-pine-hyprcursor's own
-- manifest.hl description literally says so), so native and XWayland
-- clients render matching shapes/colors instead of two unrelated themes.
```
Line 15 names `waybar`, line 16 names `swaync` — both retired packages, listed among "native Wayland client[s]" that still exist and still need cursor theming (kitty, walker, quickshell, Thunar). Per D-21-19 ("comments naming a retired surface are rewritten, never scrubbed"), the fix is to replace `waybar`/`swaync` with their current equivalents (the Quickshell bar; the in-repo notification surface's current name/requirement-ID) in this enumeration — not to delete the two retired names outright, but to rewrite the list to name what currently exists, following the same rewrite discipline `autostart.lua:186`, `windowrules.lua`, and `quickshell-doctor:723` already apply correctly (cited in D-22-07 as the examples to match, not touch).

## Shared Patterns

### `[PASS]`/`[FAIL]`/`[SKIP]` line-stream protocol
**Source:** `retirement-check`, `motion-lint`, `colour-lint` — all three emit exactly `[PASS]`/`[FAIL]`/`[SKIP]`/`[EXEMPT]`/`[REPORT]` tagged lines on stdout, parsed by `theme-doctor`'s folds via a bash `case "$_line" in *"[PASS]"*) ... ;; *"[FAIL]"*) ... ;; *) echo passthrough ;; esac` idiom.
**Apply to:** the new dangling-symlink checker's stdout format — it MUST emit this exact tag vocabulary so its `theme-doctor` fold can reuse the identical case-statement idiom verbatim.

### Deny-by-default + committed, reasoned exemption list
**Source:** `motion-lint` lines 47-57, `colour-lint` lines 59-75, `retirement-check`'s registry comment lines 77-95 — every entry requires a non-empty `reason`, is printed on every run (never silently discarded), and (motion-lint/colour-lint) carries a structured `pending: bool` field rather than a prose substring.
**Apply to:** the new D-22-08/09/10 session-failure allowlist — same discipline: every admitted `theme-doctor` failure needs a structural reason (per D-22-09: "no session bus / no compositor / no display / no user session", sourced from `theme-doctor`'s own code, not from what happened to go red).

### `--self-test` against committed fixtures, never a one-time demonstration
**Source:** D-28, cited identically in `retirement-check` (lines 49-52), `motion-lint` (lines 70-76), `colour-lint` (lines 86-92): "a gate that cannot be pointed at a fixture cannot be proven to fail."
**Apply to:** the new dangling-symlink checker — mandatory `--self-test` entry point against committed compliant/poisoned fixture trees, exactly as D-22-06 states explicitly.

### Guarded-skip-when-absent, unguarded-when-filesystem-only
**Source:** `theme-doctor`'s three folds — Fold 2 (`hypr-equivalence-check`) is the only one gated on a live session (`HYPRLAND_INSTANCE_SIGNATURE`); Folds 1 and 3 (`motion-lint`, `colour-lint`) gate ONLY on `[[ -x "$CHECKER" ]]`, i.e., degrade to `[SKIP]` only if the checker binary itself is missing/unstowed, and otherwise always run — including headless in the container.
**Apply to:** the new dangling-symlink checker's fold — it is filesystem-only (no compositor dependency), so it must use the unguarded Fold-1/Fold-3 shape, not Fold-2's live-session guard, so it actually executes inside `verify/container-run.sh`'s headless container per D-22-05/D-22-06's intent.

## No Analog Found

None — every file in this phase's scope has at least a role-match analog inside this repo; no file requires falling back to RESEARCH.md patterns (RESEARCH.md does not exist for this phase; CONTEXT.md's own canonical references were sufficient).

## Metadata

**Analog search scope:** `hypr/.config/hypr/scripts/` (checkers + fixtures), `theme-engine/.config/theme-engine/theme-doctor`, `verify/container-run.sh`, `VERIFICATION.md`, `README.md`, `hypr/.config/hypr/config/env.lua`, `stow.sh` — all read directly, no Glob/Grep-only inference.
**Files scanned (full or targeted read):** `22-CONTEXT.md`, `retirement-check` (full, 767 lines), `motion-lint` (full, 1184 lines), `colour-lint` (full, 746 lines), `container-run.sh` (full, 301 lines), `theme-doctor` (targeted, lines 455-570), `stow.sh` (targeted, lines 1-30 + 190-229), `VERIFICATION.md` (full, 251 lines), `README.md` (targeted, lines 1-90), `env.lua` (targeted, lines 1-25), plus a `find` listing of `tests/retirement-fixtures/` and two of its five fixture subtrees.
**Pattern extraction date:** 2026-08-16
