#!/usr/bin/env bash
# 17-cut-sweep.sh — Phase 17 (Ambient Extras) criterion-3 consumer-check sweep.
#
# WHY THIS LIVES UNDER .planning/, NOT hypr/.config/hypr/scripts/:
# This is phase-scoped audit tooling. No desktop session ever runs it —
# it exists to answer one question at this phase's close: does any
# consumer (stow.sh, install.sh, windowrules, contract.json, QML imports)
# still reference something Phase 17 started and did not finish? Putting
# it in the stowed scripts directory would add a PERMANENT stowed surface
# for a ONE-PHASE concern — exactly the additive scaffolding drift this
# phase Owns, committed by the very plan that sweeps for it. Living under
# .planning/ means stow.sh needs no edit (standing constraint #3 is
# satisfied by having nothing to register), and a wholesale revert of
# Phase 17 takes this sweep with it. Do not "helpfully" relocate this
# script into hypr/.config/hypr/scripts/ — that would be the drift.
#
# REPORT-ONLY BY CONSTRUCTION. This script contains no destructive verb
# (no rm, no mv, no truncate, no pkill, no hyprpm mutation) and no
# privilege escalation (no sudo) anywhere. Every remediation this script
# discovers is PRINTED AS TEXT for a human to run — never executed. D-38's
# hyprpm-artifact clause is the sharpest instance of this: the sweep
# inspects and reports on root-owned host state, and never acts on it.
#
# set -uo pipefail, deliberately NOT -e (matching theme-doctor's own
# convention): a sweep must survive every individual check failing and
# still print the rest of its report.
set -uo pipefail

# ── Resolve repo root and phase dir from the script's own location ──────
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PHASE_DIR="$(dirname "$SCRIPT_PATH")"
REPO_ROOT="$(readlink -f "$PHASE_DIR/../../..")"
MANIFEST="$PHASE_DIR/17-cut-sweep-manifest.tsv"

# ── Verdict counters (per reporting label) ───────────────────────────────
_OK=0
_FAIL=0
_DRIFT=0
_WARN=0
_INFO=0

# ── The completion oracle ────────────────────────────────────────────────
# "Finished" is defined mechanically, once: the producing plan's SUMMARY
# exists at .planning/phases/17-ambient-extras/17-0N-SUMMARY.md. This is
# GSD's own completion contract, the same marker the orchestrator reads,
# and exactly the line criterion 3 draws between work that finished and
# work the phase started and did not finish. One honest limitation: a
# plan can be partially committed without a SUMMARY, and under this
# oracle every reference it left behind is reported as drift — the
# correct and intended reading of the criterion, not an over-report.
#
# Parameterized by <dir> so --self-test can point it at a synthesised
# throwaway directory instead of this phase's real SUMMARYs.
_plan_finished() {
    local dir="$1" plan="$2"
    if [[ -f "$dir/17-${plan}-SUMMARY.md" ]]; then
        echo yes
    else
        echo no
    fi
}

# ── The verdict function — PURE. Three explicit arguments, one output. ──
# No filesystem access of its own — no path test, no grep, no find. This
# is the same purity lesson quickshell-doctor's T-16-SELFTEST note already
# records: an assertion doing its own live lookup only passes on the host
# it was captured on. Purity here is what lets --self-test drive all four
# states deterministically, with no repo path involved.
_verdict() {
    local plan_finished="$1" artifact_present="$2" ref_present="$3"
    if [[ "$plan_finished" == "yes" ]]; then
        if [[ "$artifact_present" == "yes" && "$ref_present" == "yes" ]]; then
            echo "ok"
        else
            echo "incomplete"
        fi
    else
        if [[ "$artifact_present" == "no" && "$ref_present" == "no" ]]; then
            echo "ok-not-started"
        else
            echo "drift"
        fi
    fi
}

# ── ARTIFACT predicate interpreter ───────────────────────────────────────
# Closed vocabulary: exec: / file: / dir: / sym:<path>::<literal> / none.
# Dispatches on a case over known prefixes; an unknown prefix is a loud
# error naming the row, never a silent pass. `<user>` is substituted with
# the real invoking user (id -un) — used only by D-38's host-only hyprpm
# artifact row, never shell-evaluated.
_artifact_present() {
    local row_id="$1" spec="$2"
    spec="${spec//<user>/$(id -un)}"
    case "$spec" in
        exec:*)
            local p="${spec#exec:}"
            [[ -f "$p" && -x "$p" ]] && echo yes || echo no
            ;;
        file:*)
            local p="${spec#file:}"
            [[ -f "$p" ]] && echo yes || echo no
            ;;
        dir:*)
            local p="${spec#dir:}"
            [[ -d "$p" ]] && echo yes || echo no
            ;;
        sym:*)
            local rest="${spec#sym:}"
            local p="${rest%%::*}"
            local lit="${rest#*::}"
            if [[ -f "$p" ]] && grep -qF -- "$lit" "$p" 2>/dev/null; then
                echo yes
            else
                echo no
            fi
            ;;
        none)
            echo no
            ;;
        *)
            echo "FATAL: row $row_id carries an unknown ARTIFACT prefix: '$spec'" >&2
            exit 2
            ;;
    esac
}

# ── CONSUMER + SCOPE + REF matcher ───────────────────────────────────────
# CONSUMER: repo-relative path, "-" (no consumer), or "glob:<name-pattern>"
#   (enumerate every matching file via `find . -name <pattern>`, excluding
#   .git — used only by E-02/E-03's "every *.qml in the repo" assertions).
# SCOPE: file (whole file) / array:<NAME> (the array's own parenthesised
#   block, sed-extracted the same way 17-04's own criteria already do
#   against this same install.sh shape) / nocomment (comment-stripped).
# REF: fixed string by default; an ERE only when prefixed `re:`. No
#   shell evaluation anywhere — every command below is a bash array or a
#   direct invocation, never a string handed to `eval`.
_ref_present() {
    local row_id="$1" consumer="$2" scope="$3" ref="$4"
    consumer="${consumer//<user>/$(id -un)}"

    if [[ "$consumer" == "-" ]]; then
        echo no
        return
    fi

    local -a files=()
    case "$consumer" in
        glob:*)
            local pattern="${consumer#glob:}"
            while IFS= read -r -d '' f; do
                files+=("$f")
            done < <(find "$REPO_ROOT" -name "$pattern" -not -path '*/.git/*' -print0 2>/dev/null)
            ;;
        *)
            files=("$REPO_ROOT/$consumer")
            ;;
    esac

    local found=no
    local f content
    for f in "${files[@]}"; do
        [[ -f "$f" ]] || continue
        case "$scope" in
            file)
                content="$(cat -- "$f")"
                ;;
            nocomment)
                content="$(grep -v '^[[:space:]]*#' -- "$f")"
                ;;
            array:*)
                local name="${scope#array:}"
                content="$(sed -n "/^${name}=(/,/^)/p" -- "$f")"
                ;;
            *)
                echo "FATAL: row $row_id carries an unknown SCOPE prefix: '$scope'" >&2
                exit 2
                ;;
        esac
        case "$ref" in
            re:*)
                local pat="${ref#re:}"
                if grep -qE -- "$pat" <<<"$content"; then
                    found=yes
                fi
                ;;
            *)
                if grep -qF -- "$ref" <<<"$content"; then
                    found=yes
                fi
                ;;
        esac
    done
    echo "$found"
}

# Returns the (file, 1-based line number) of the first REF match, for
# [DRIFT] reporting. Best-effort text only — never used for verdict logic.
_ref_locate() {
    local consumer="$2" scope="$3" ref="$4"
    consumer="${consumer//<user>/$(id -un)}"
    [[ "$consumer" == "-" || "$consumer" == glob:* ]] && { echo "(no single location)"; return; }
    local f="$REPO_ROOT/$consumer"
    [[ -f "$f" ]] || { echo "$consumer (missing)"; return; }
    local pat="$ref"
    local grep_flag="-F"
    if [[ "$ref" == re:* ]]; then
        pat="${ref#re:}"
        grep_flag="-E"
    fi
    local line
    line="$(grep -n $grep_flag -- "$pat" "$f" 2>/dev/null | head -n1 | cut -d: -f1)"
    if [[ -n "$line" ]]; then
        echo "$consumer:$line"
    else
        echo "$consumer (ref not found)"
    fi
}

# ── Reporting helper ──────────────────────────────────────────────────────
_report() {
    local label="$1" id="$2" msg="$3"
    case "$label" in
        OK) _OK=$((_OK+1)) ;;
        FAIL) _FAIL=$((_FAIL+1)) ;;
        DRIFT) _DRIFT=$((_DRIFT+1)) ;;
        WARN) _WARN=$((_WARN+1)) ;;
        INFO) _INFO=$((_INFO+1)) ;;
    esac
    printf '[%s] %s %s\n' "$label" "$id" "$msg"
}

# ── One manifest row → one verdict ───────────────────────────────────────
_process_row() {
    local id="$1" plan="$2" unit="$3" artifact="$4" consumer="$5" scope="$6" ref="$7" mode="$8" note="$9"
    local plan_num="${plan#17-}"

    case "$mode" in
        pair)
            local pf art rf v
            pf="$(_plan_finished "$PHASE_DIR" "$plan_num")"
            art="$(_artifact_present "$id" "$artifact")"
            rf="$(_ref_present "$id" "$consumer" "$scope" "$ref")"
            v="$(_verdict "$pf" "$art" "$rf")"
            case "$v" in
                ok)
                    _report OK "$id" "$unit -> $consumer [finished, wired]${note:+ — $note}"
                    ;;
                ok-not-started)
                    _report OK "$id" "$unit -> $consumer [not started]${note:+ — $note}"
                    ;;
                incomplete)
                    _report FAIL "$id" "$unit -> $consumer [plan_finished=$pf artifact=$art ref=$rf] — reported done but wiring incomplete${note:+ — $note}"
                    ;;
                drift)
                    local loc
                    loc="$(_ref_locate "$id" "$consumer" "$scope" "$ref")"
                    _report DRIFT "$id" "$unit -> $loc — CRITERION-3 VIOLATION: consumer references unfinished work (plan_finished=$pf)${note:+ — $note}. Remediation: revert the reference in $consumer, or finish and commit ${plan}'s SUMMARY."
                    ;;
            esac
            ;;
        branch)
            local art rf
            art="$(_artifact_present "$id" "$artifact")"
            rf="$(_ref_present "$id" "$consumer" "$scope" "$ref")"
            if [[ "$art" == "$rf" ]]; then
                _report OK "$id" "$unit <-> $consumer [symmetric: artifact=$art ref=$rf]${note:+ — $note}"
            else
                _report FAIL "$id" "$unit <-> $consumer [ASYMMETRIC: artifact=$art ref=$rf] — orphan or dangling wiring${note:+ — $note}"
            fi
            ;;
        warn)
            local pf art
            pf="$(_plan_finished "$PHASE_DIR" "$plan_num")"
            art="$(_artifact_present "$id" "$artifact")"
            local detail=""
            if [[ "$art" == "yes" ]]; then
                local p="${artifact//<user>/$(id -un)}"
                p="${p#dir:}"
                local owner mtime
                owner="$(stat -c '%U' "$p" 2>/dev/null || echo unknown)"
                mtime="$(stat -c '%y' "$p" 2>/dev/null || echo unknown)"
                detail="present, owner=$owner, mtime=$mtime"
            else
                detail="absent"
            fi
            if [[ "$pf" == "no" ]]; then
                _report WARN "$id" "$unit [$detail] — ${note}"
            else
                _report INFO "$id" "$unit [$detail] — ${note}"
            fi
            ;;
        empty)
            local rf
            rf="$(_ref_present "$id" "$consumer" "$scope" "$ref")"
            if [[ "$rf" == "no" ]]; then
                _report OK "$id" "$unit — asserted empty, confirmed zero hits in $consumer${note:+ — $note}"
            else
                local loc
                loc="$(_ref_locate "$id" "$consumer" "$scope" "$ref")"
                _report FAIL "$id" "$unit — INVARIANT VIOLATED: unexpected reference found at $loc${note:+ — $note}"
            fi
            ;;
        *)
            echo "FATAL: row $id carries an unknown MODE: '$mode'" >&2
            exit 2
            ;;
    esac
}

# ── Full-manifest run ─────────────────────────────────────────────────────
_run_manifest() {
    [[ -f "$MANIFEST" ]] || { echo "FATAL: manifest not found at $MANIFEST" >&2; exit 2; }
    local line
    while IFS=$'\t' read -r c1 c2 c3 c4 c5 c6 c7 c8 c9; do
        [[ "$c1" =~ ^#.*$ || -z "$c1" ]] && continue
        _process_row "$c1" "$c2" "$c3" "$c4" "$c5" "$c6" "$c7" "$c8" "${c9:-}"
    done < "$MANIFEST"

    printf '\n[INFO] summary OK=%d FAIL=%d DRIFT=%d WARN=%d INFO=%d\n' "$_OK" "$_FAIL" "$_DRIFT" "$_WARN" "$_INFO"

    if [[ "$_FAIL" -gt 0 || "$_DRIFT" -gt 0 ]]; then
        return 1
    fi
    return 0
}

# ── --self-test: synthesise fixtures under mktemp -d, prove all four ────
# verdict states plus WARN/INFO non-effect on exit code, plus the unknown-
# prefix loud-failure path. Fixtures are synthesised at runtime, never
# committed — a real hyprctl-layers-style snapshot can't be faithfully
# synthesised (quickshell-doctor's reason for committing JSON fixtures),
# but a two-line text file can be, and committing scaffolding fixtures
# inside the plan that sweeps for committed scaffolding would itself be a
# finding.
_self_test() {
    local tmp
    tmp="$(mktemp -d)"
    # No cleanup call here by design (T-17-18): this script contains no
    # destructive verb anywhere, including its own self-test scratch
    # space. mktemp -d hands out a path under the OS's own temp area,
    # which the OS is already responsible for reclaiming — the sweep
    # never removes anything, not even something it created itself.

    local pass=0 fail=0

    _assert_eq() {
        local desc="$1" expected="$2" actual="$3"
        if [[ "$expected" == "$actual" ]]; then
            echo "  [PASS] $desc"
            pass=$((pass+1))
        else
            echo "  [FAIL] $desc (expected='$expected' actual='$actual')"
            fail=$((fail+1))
        fi
    }

    echo "--- self-test: verdict function purity, all four states ---"
    _assert_eq "ok: finished+wired"        "ok"              "$(_verdict yes yes yes)"
    _assert_eq "ok-not-started: nothing"   "ok-not-started"  "$(_verdict no no no)"
    _assert_eq "incomplete: half-wired"    "incomplete"      "$(_verdict yes no yes)"
    _assert_eq "incomplete: half-wired-2"  "incomplete"      "$(_verdict yes yes no)"
    _assert_eq "drift: unfinished+ref"     "drift"           "$(_verdict no no yes)"
    _assert_eq "drift: unfinished+artifact" "drift"          "$(_verdict no yes no)"

    echo "--- self-test: the drift path, replayed through the real pipeline ---"
    mkdir -p "$tmp/phase"
    printf 'line one\nTOKEN_DRIFT_MARKER lives here\nline three\n' > "$tmp/consumer.txt"
    : > "$tmp/artifact.txt"
    # No SUMMARY for plan 99 -> plan_finished=no. Artifact present, ref
    # present -> must be DRIFT, and the located line must be line 2.
    local pf art rf v
    pf="$(_plan_finished "$tmp/phase" "99")"
    art="$(_artifact_present "SELF-TEST" "file:$tmp/artifact.txt")"
    rf="$(_ref_present "SELF-TEST" "${tmp#$REPO_ROOT/}consumer.txt" "file" "TOKEN_DRIFT_MARKER")"
    # _ref_present resolves relative to REPO_ROOT; do a direct local check
    # instead, since $tmp is outside the repo tree.
    if grep -qF -- "TOKEN_DRIFT_MARKER" "$tmp/consumer.txt"; then rf=yes; else rf=no; fi
    v="$(_verdict "$pf" "$art" "$rf")"
    _assert_eq "drift replay: plan_finished" "no" "$pf"
    _assert_eq "drift replay: artifact_present" "yes" "$art"
    _assert_eq "drift replay: ref_present" "yes" "$rf"
    _assert_eq "drift replay: verdict" "drift" "$v"
    local locline
    locline="$(grep -n -F -- "TOKEN_DRIFT_MARKER" "$tmp/consumer.txt" | head -n1 | cut -d: -f1)"
    _assert_eq "drift replay: line number located" "2" "$locline"

    echo "--- self-test: ok replay (plan finished, both present) ---"
    # A second, separate phase-dir carries the SUMMARY, so the
    # "not started" replay below never has to remove anything — it
    # simply reads a phase-dir that never had one.
    mkdir -p "$tmp/phase-finished"
    printf 'placeholder\n' > "$tmp/phase-finished/17-99-SUMMARY.md"
    pf="$(_plan_finished "$tmp/phase-finished" "99")"
    v="$(_verdict "$pf" yes yes)"
    _assert_eq "ok replay: plan_finished" "yes" "$pf"
    _assert_eq "ok replay: verdict" "ok" "$v"

    echo "--- self-test: ok-not-started replay (plan not finished, nothing present) ---"
    mkdir -p "$tmp/phase-not-started"
    pf="$(_plan_finished "$tmp/phase-not-started" "99")"
    v="$(_verdict "$pf" no no)"
    _assert_eq "ok-not-started replay: plan_finished" "no" "$pf"
    _assert_eq "ok-not-started replay: verdict" "ok-not-started" "$v"

    echo "--- self-test: predicate interpreters, closed vocabulary ---"
    _assert_eq "artifact exec: not-yet-executable is no" "no" "$(_artifact_present T "exec:$tmp/artifact.txt")"
    chmod +x "$tmp/artifact.txt"
    _assert_eq "artifact exec: executable" "yes" "$(_artifact_present T "exec:$tmp/artifact.txt")"
    _assert_eq "artifact file: present"  "yes" "$(_artifact_present T "file:$tmp/artifact.txt")"
    _assert_eq "artifact dir: absent"    "no"  "$(_artifact_present T "dir:$tmp/nonexistent")"
    mkdir -p "$tmp/adir"
    _assert_eq "artifact dir: present"   "yes" "$(_artifact_present T "dir:$tmp/adir")"
    printf 'needle-value\n' > "$tmp/sym.txt"
    _assert_eq "artifact sym: literal found" "yes" "$(_artifact_present T "sym:$tmp/sym.txt::needle-value")"
    _assert_eq "artifact sym: literal absent" "no" "$(_artifact_present T "sym:$tmp/sym.txt::not-there")"
    _assert_eq "artifact none: always no"  "no"  "$(_artifact_present T "none")"

    echo "--- self-test: WARN/INFO never change exit code ---"
    _OK=0; _FAIL=0; _DRIFT=0; _WARN=0; _INFO=0
    _report WARN "SELF-TEST-W" "synthetic warn line"
    _report INFO "SELF-TEST-I" "synthetic info line"
    if [[ "$_FAIL" -eq 0 && "$_DRIFT" -eq 0 ]]; then
        echo "  [PASS] WARN+INFO recorded ($_WARN warn, $_INFO info) with FAIL=0 DRIFT=0 -> exit would be 0"
        pass=$((pass+1))
    else
        echo "  [FAIL] WARN/INFO unexpectedly affected FAIL/DRIFT counters"
        fail=$((fail+1))
    fi
    _OK=0; _FAIL=0; _DRIFT=0; _WARN=0; _INFO=0

    echo "--- self-test: unknown prefix is loud, not silent ---"
    if ( _artifact_present "POISON-ROW" "bogus:/nonexistent" >/dev/null 2>&1 ); then
        echo "  [FAIL] unknown ARTIFACT prefix did not exit nonzero"
        fail=$((fail+1))
    else
        echo "  [PASS] unknown ARTIFACT prefix exits nonzero and names the row (POISON-ROW)"
        pass=$((pass+1))
    fi

    echo ""
    echo "self-test: $pass passed, $fail failed"
    [[ "$fail" -eq 0 ]]
}

# ── Entrypoint ─────────────────────────────────────────────────────────
case "${1:-}" in
    --self-test)
        _self_test
        exit $?
        ;;
    "")
        _run_manifest
        exit $?
        ;;
    *)
        echo "usage: $0 [--self-test]" >&2
        exit 2
        ;;
esac
