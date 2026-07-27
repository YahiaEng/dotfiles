#!/usr/bin/env bash
# theme-engine/lib/motion.sh — motion-token theme-orthogonal axis (D-01,
# D-05, D-09, D-21; mirrors font.sh's three-shape convention exactly)
#
# Motion is the THIRD theme-orthogonal state axis, after font-choice and
# icon-theme: its own state file under $STATE_DIR (motion-scale), excluded
# from commit.sh's rsync --delete via contract.json's engine_owned_files,
# and re-rendered on EVERY theme-apply run regardless of which theme or mode
# is active — same four guarantees font.sh already established twice. New
# relative to font.sh: a render-time validation + clamp pass (D-02(a)/D-09)
# runs before any of the three motion targets is written, because the
# Hyprland and GTK4 targets have no readback and GTK4 silently drops a
# single bad rule (the Phase 9 finding) — a malformed value must never
# reach either parser.
#
# motion.json (hand-authored, $HOME/.config/theme-engine/motion.json) is the
# SOLE source of every duration/control-point number this file emits (D-05):
# durations + easings are the two base layers, semantic pairs reference them
# BY NAME, never by inlined value — no number is ever written twice anywhere
# in this pipeline.

MOTION_STATE_FILE="$HOME/.local/state/theme/motion-scale"
MOTION_DEFAULT="normal"
MOTION_JSON="$HOME/.config/theme-engine/motion.json"

# D-13: Hyprland's animation `speed` unit, confirmed by a human-observed
# extreme-value probe (13-01 Task 2 — `speed = 500` on a live `layers` slot
# timed at ~50s, falsifying/confirming the wiki's documented ds claim
# against a stopwatch rather than trusting a readback). 1 speed unit = 100ms.
MOTION_HYPR_SPEED_DIVISOR_DS=100

# T-13-01/D-21: the A/B curve-set comparison toggle's state file. Same
# theme-orthogonal shape as MOTION_STATE_FILE above, but selects which
# `curve_sets` entry (motion.json) feeds the six feel-changing Hyprland
# slots (windows-in/out/move, fade-in/out, workspaces) rather than the
# scale multiplier. Temporary — removed in plan 13-07 alongside
# motion.json's `curve_sets` object.
MOTION_CURVES_FILE="$HOME/.local/state/theme/motion-curves"
MOTION_CURVES_DEFAULT="md3"

# theme_engine_read_motion_scale
# Echoes the current motion-scale state value, defaulting to "normal" when
# the axis has never been set OR holds an unrecognised value. D-21 requires
# a closed-set `case` here (unlike font.sh's free-text read) — this value
# flows into jq filters and into a file Hyprland's config parser consumes,
# so an arbitrary string must never pass through unvalidated (ASVS V5).
theme_engine_read_motion_scale() {
    local v
    v="$(cat "$MOTION_STATE_FILE" 2>/dev/null || echo "$MOTION_DEFAULT")"
    case "$v" in
        off|reduced|normal|lively) echo "$v" ;;
        *) echo "$MOTION_DEFAULT" ;;
    esac
}

# theme_engine_read_motion_curves
# Echoes the current curve-set (D-21's A/B toggle) state value, defaulting
# to "md3" when the axis has never been set OR holds an unrecognised value.
# Identical closed-`case` shape to theme_engine_read_motion_scale above —
# this value flows into $motion_curve_* variables inside a file Hyprland's
# config parser consumes (T-13-01), so an out-of-set value must never pass
# through unvalidated.
theme_engine_read_motion_curves() {
    local v
    v="$(cat "$MOTION_CURVES_FILE" 2>/dev/null || echo "$MOTION_CURVES_DEFAULT")"
    case "$v" in
        md3|legacy) echo "$v" ;;
        *) echo "$MOTION_CURVES_DEFAULT" ;;
    esac
}

# theme_engine_validate_motion_values <multiplier> <floor_ms>
# D-02(a) render-time guard — the ONLY guard that reaches the Hyprland and
# GTK4 targets (neither has a readback, and GTK4 silently drops a single bad
# rule rather than failing loud). Asserts the two-layer schema is
# well-formed and every semantic reference resolves to a positive duration
# BEFORE a single byte is written. Diagnoses the offending token to stderr
# and returns non-zero on any violation — theme-apply already routes a
# non-zero theme_engine_generate into .last-render-error.log and leaves the
# desktop unchanged.
theme_engine_validate_motion_values() {
    local multiplier="$1"
    local floor_ms="$2"

    if [[ ! -s "$MOTION_JSON" ]] || ! jq -e . "$MOTION_JSON" >/dev/null 2>&1; then
        echo "motion.sh: $MOTION_JSON is missing, empty, or not valid JSON" >&2
        return 1
    fi

    if ! jq -e '(.durations // {}) | length > 0' "$MOTION_JSON" >/dev/null 2>&1; then
        echo "motion.sh: motion.json 'durations' layer is missing or empty" >&2
        return 1
    fi
    if ! jq -e '(.easings // {}) | length > 0' "$MOTION_JSON" >/dev/null 2>&1; then
        echo "motion.sh: motion.json 'easings' layer is missing or empty" >&2
        return 1
    fi
    if ! jq -e '(.semantic // {}) | length > 0' "$MOTION_JSON" >/dev/null 2>&1; then
        echo "motion.sh: motion.json 'semantic' layer is missing or empty" >&2
        return 1
    fi

    local bad_easings
    bad_easings="$(jq -r '
        .easings | to_entries[]
        | select((.value | type != "array") or (.value | length != 4)
                 or ([.value[] | (type != "number") or isnan or isinfinite] | any))
        | .key' "$MOTION_JSON" 2>/dev/null)"
    if [[ -n "$bad_easings" ]]; then
        echo "motion.sh: easing(s) with malformed control points (need exactly 4 finite numbers): $bad_easings" >&2
        return 1
    fi

    local bad_refs
    bad_refs="$(jq -r '
        .durations as $D | .easings as $E
        | .semantic | to_entries[]
        | select(($D[.value.duration] // null) == null or ($E[.value.easing] // null) == null)
        | .key' "$MOTION_JSON" 2>/dev/null)"
    if [[ -n "$bad_refs" ]]; then
        echo "motion.sh: semantic pair(s) with an unresolvable duration/easing name: $bad_refs" >&2
        return 1
    fi

    local bad_durations
    bad_durations="$(jq -r '
        .durations as $D
        | .semantic | to_entries[]
        | .value.duration as $dn | ($D[$dn]) as $dv
        | select(($dv | type != "number") or ($dv | isnan) or ($dv | isinfinite))
        | .key' "$MOTION_JSON" 2>/dev/null)"
    if [[ -n "$bad_durations" ]]; then
        echo "motion.sh: semantic pair(s) reference a non-numeric duration value: $bad_durations" >&2
        return 1
    fi

    local positivity
    positivity="$(jq -n --argjson floor "$floor_ms" --argjson mult "$multiplier" '$floor > 0 and $mult > 0' 2>/dev/null)"
    if [[ "$positivity" != "true" ]]; then
        echo "motion.sh: floor_ms ($floor_ms) and the active scale's multiplier ($multiplier) must both be positive numbers" >&2
        return 1
    fi

    local bad_resolved
    bad_resolved="$(jq -r --argjson mult "$multiplier" --argjson floor "$floor_ms" '
        .durations as $D
        | .semantic | to_entries[]
        | .value.duration as $dn | ($D[$dn] * $mult) as $scaled
        | (if $scaled < $floor then $floor else $scaled end) as $clamped
        | select(($clamped | floor) <= 0)
        | .key' "$MOTION_JSON" 2>/dev/null)"
    if [[ -n "$bad_resolved" ]]; then
        echo "motion.sh: semantic pair(s) resolve to a non-positive duration after the D-09 clamp: $bad_resolved" >&2
        return 1
    fi

    # 13-01 Task 3G: extend validation to the two new top-level categories
    # (indicators, curve_sets) added alongside the D-21 A/B toggle — same
    # validate-before-any-write discipline, same diagnose-to-stderr shape.
    local bad_indicators
    bad_indicators="$(jq -r '
        .easings as $E
        | (.indicators // {}) | to_entries[]
        | select(
            (.value.duration_ms | type != "number") or (.value.duration_ms | isnan)
            or (.value.duration_ms | isinfinite) or (.value.duration_ms <= 0)
            or (($E[.value.easing] // null) == null)
          )
        | .key' "$MOTION_JSON" 2>/dev/null)"
    if [[ -n "$bad_indicators" ]]; then
        echo "motion.sh: indicator(s) with a non-positive/non-finite duration_ms or an unresolvable easing: $bad_indicators" >&2
        return 1
    fi

    local bad_curve_sets
    bad_curve_sets="$(jq -r '
        .easings as $E
        | (.curve_sets // {}) | to_entries[]
        | .key as $set | .value as $slots
        | ($slots | to_entries[] | select($E[.value] == null) | "\($set).\(.key) -> \(.value)")
    ' "$MOTION_JSON" 2>/dev/null)"
    if [[ -n "$bad_curve_sets" ]]; then
        echo "motion.sh: curve_sets slot(s) reference a non-existent easing: $bad_curve_sets" >&2
        return 1
    fi

    local active_curves
    active_curves="$(theme_engine_read_motion_curves)"
    if ! jq -e --arg c "$active_curves" '(.curve_sets // {}) | has($c)' "$MOTION_JSON" >/dev/null 2>&1; then
        echo "motion.sh: active motion-curves value '$active_curves' does not name a real curve_sets key in motion.json" >&2
        return 1
    fi

    return 0
}

# theme_engine_render_motion_files <tmp_dir>
# Renders motion.json, gtk-4.0-motion.css and hyprland-motion.conf into the
# tmp render tree — same call shape as theme_engine_render_font_files. Reads
# the motion-scale axis, resolves its multiplier/animations_enabled from
# motion.json's OWN scales table (D-21 — the multiplier table lives in
# data, not here), validates BEFORE any write, then emits all three targets
# from one shared jq computation so they can never disagree with each
# other or with the WARN pass below.
theme_engine_render_motion_files() {
    local tmp="$1"
    local scale multiplier animations_enabled floor_ms

    scale="$(theme_engine_read_motion_scale)"

    if [[ ! -s "$MOTION_JSON" ]] || ! jq -e . "$MOTION_JSON" >/dev/null 2>&1; then
        echo "motion.sh: $MOTION_JSON is missing, empty, or not valid JSON" >&2
        return 1
    fi

    multiplier="$(jq -r --arg s "$scale" '.scales[$s].multiplier // empty' "$MOTION_JSON")"
    # D-08/D-20 fix: `// empty` treats JSON `false` as absent (jq's `//`
    # alternative operator falls through on both null AND false), which
    # silently broke the "off" preset — its whole point is
    # animations_enabled == false. `has()` distinguishes "key present and
    # false" from "key genuinely missing", which `// empty` cannot.
    animations_enabled="$(jq -r --arg s "$scale" '
        if (.scales[$s] // {} | has("animations_enabled"))
        then (.scales[$s].animations_enabled | tostring)
        else empty end' "$MOTION_JSON")"
    floor_ms="$(jq -r '.floor_ms // empty' "$MOTION_JSON")"

    if [[ -z "$multiplier" || -z "$animations_enabled" || -z "$floor_ms" ]]; then
        echo "motion.sh: motion.json is missing scales.'$scale' or floor_ms" >&2
        return 1
    fi

    if ! theme_engine_validate_motion_values "$multiplier" "$floor_ms"; then
        return 1
    fi

    # Single shared resolution, TSV: token, easing-name, resolved-ms,
    # clamped(true|false) — every writer below AND the WARN pass read this
    # SAME computation.
    local resolved
    resolved="$(jq -r --argjson mult "$multiplier" --argjson floor "$floor_ms" '
        .durations as $D
        | .semantic | to_entries[]
        | .key as $k | .value as $v
        | ($D[$v.duration] * $mult) as $scaled
        | (if $scaled < $floor then $floor else $scaled end) as $clamped
        | [$k, $v.easing, (($clamped | floor) | tostring), ($scaled < $floor | tostring)]
        | @tsv
    ' "$MOTION_JSON")"

    # D-09: warn (never fail) on every clamp event, one line per token,
    # through the same channel generate.sh's own render step already logs
    # matugen failures to. Sanitized with the theme-apply/theme-stress-test
    # idiom before it could ever reach a notification.
    while IFS=$'\t' read -r token _easing _ms clamped_flag; do
        [[ -z "$token" ]] && continue
        if [[ "$clamped_flag" == "true" ]]; then
            local warn_msg
            warn_msg="WARN — ${token} collapsed to the ${floor_ms}ms floor at motion-scale '${scale}'; this is expected and imperceptible, not a failure."
            warn_msg="$(printf '%s' "$warn_msg" | head -c 200 | tr -d '\000-\011\013\014\016-\037')"
            printf '%s\n' "$warn_msg" >> "${GENERATE_LOG:-/dev/null}"
        fi
    done <<< "$resolved"

    local out_dir="$tmp$STATE_DIR"
    mkdir -p "$out_dir"

    # 13-01 Task 3H: the active curve-set (D-21 A/B toggle) and the three new
    # TSVs it/the semantic-scale resolution feed into the Hyprland writer's
    # new $motion_speed_*/$motion_curve_* families below.
    local active_curves
    active_curves="$(theme_engine_read_motion_curves)"

    local speed_semantic
    speed_semantic="$(jq -r --argjson mult "$multiplier" --argjson floor "$floor_ms" '
        .durations as $D
        | .semantic | to_entries[]
        | .key as $k | .value as $v
        | ($D[$v.duration] * $mult) as $scaled
        | (if $scaled < $floor then $floor else $scaled end) as $clamped
        | [($k | gsub("-"; "_")), (($clamped | floor) | tostring)]
        | @tsv
    ' "$MOTION_JSON")"

    local speed_indicators
    speed_indicators="$(jq -r --argjson mult "$multiplier" --argjson floor "$floor_ms" '
        (.indicators // {}) | to_entries[]
        | .key as $k | .value as $v
        | ($v.duration_ms * $mult) as $scaled
        | (if $scaled < $floor then $floor else $scaled end) as $clamped
        | [($k | gsub("-"; "_")), (($clamped | floor) | tostring)]
        | @tsv
    ' "$MOTION_JSON")"

    local curve_vars
    curve_vars="$(jq -r --arg c "$active_curves" '
        (.curve_sets[$c] // {}) | to_entries[]
        | "\(.key | gsub("-"; "_"))\t\(.value)"
    ' "$MOTION_JSON")"

    # ── 1. Hyprland target: $motion_enabled first as a top-level assignment,
    #    then the new $motion_speed_*/$motion_speed_indicator_*/
    #    $motion_curve_* families (Task 3H), then an animations {} block
    #    holding ONLY bezier = lines (D-22: no `enabled =` key here —
    #    animations.conf owns that; D-04: no `animation =` line either —
    #    Phase 12 fences to curves only) ───────────────────────────────────
    {
        # shellcheck disable=SC2016 # intentional: literal $ for Hyprland's variable syntax, not shell expansion
        printf '$motion_enabled = %s\n' "$animations_enabled"

        # $motion_speed_<token> — one per .semantic entry, in Hyprland's
        # decisecond speed unit (D-13, MOTION_HYPR_SPEED_DIVISOR_DS), two
        # decimal places so a sub-100ms-per-unit remainder never truncates
        # away (e.g. 150ms -> 1.50, not 1).
        while IFS=$'\t' read -r token ms; do
            [[ -z "$token" ]] && continue
            # shellcheck disable=SC2016
            printf '$motion_speed_%s = %s\n' "$token" \
                "$(awk -v ms="$ms" -v d="$MOTION_HYPR_SPEED_DIVISOR_DS" 'BEGIN{printf "%.2f", ms/d}')"
        done <<< "$speed_semantic"

        # $motion_speed_indicator_<name> — one per .indicators entry, scaled
        # by the SAME multiplier/floor as the semantic pairs so `reduced`
        # and `lively` reach indicators too.
        while IFS=$'\t' read -r name ms; do
            [[ -z "$name" ]] && continue
            # shellcheck disable=SC2016
            printf '$motion_speed_indicator_%s = %s\n' "$name" \
                "$(awk -v ms="$ms" -v d="$MOTION_HYPR_SPEED_DIVISOR_DS" 'BEGIN{printf "%.2f", ms/d}')"
        done <<< "$speed_indicators"

        # $motion_curve_<slot> — one per slot in the ACTIVE curve_sets set
        # (D-21 A/B toggle), resolved through theme_engine_read_motion_curves.
        while IFS=$'\t' read -r slot easing; do
            [[ -z "$slot" ]] && continue
            # shellcheck disable=SC2016
            printf '$motion_curve_%s = motion-%s\n' "$slot" "$easing"
        done <<< "$curve_vars"

        echo "animations {"
        jq -r '.easings | to_entries[] |
            "    bezier = motion-\(.key), \(.value[0]), \(.value[1]), \(.value[2]), \(.value[3])"' \
            "$MOTION_JSON"
        echo "}"
    } > "$out_dir/hyprland-motion.conf"

    # ── 2. GTK4 target: :root custom properties. WR-02: emit EVERY declared
    #    easing unconditionally, same as the Hyprland writer above
    #    (`.easings | to_entries[]`) — the two writers must agree on which
    #    easings exist (D-05/one-source-of-truth). Previously this only
    #    emitted an easing actually referenced by a semantic pair, so a
    #    declared-but-unreferenced easing (e.g. motion.json's "linear")
    #    resolved fine from Hyprland's `motion-linear` bezier but produced
    #    an unconditional motion-lint CHECK-A dangling-reference failure
    #    the moment any CSS/QML surface reached for
    #    `var(--motion-easing-linear)`. ───────────────────────────────────
    {
        echo ":root {"
        while IFS=$'\t' read -r token _easing ms _clamped; do
            [[ -z "$token" ]] && continue
            printf '  --motion-duration-%s: %sms;\n' "$token" "$ms"
        done <<< "$resolved"
        jq -r '
            .easings | to_entries[] |
            "  --motion-easing-\(.key): cubic-bezier(\(.value | join(", ")));"
        ' "$MOTION_JSON"
        echo "}"
    } > "$out_dir/gtk-4.0-motion.css"

    # ── 3. QML target: plain JSON — contract.sh's existing `json` handler
    #    already works generically, no new format branch needed ──────────
    jq -n --argjson mult "$multiplier" --argjson floor "$floor_ms" \
        --arg scale "$scale" --argjson enabled "$animations_enabled" \
        --slurpfile src "$MOTION_JSON" '
        $src[0] as $m
        | $m.durations as $D | $m.easings as $E
        | {
            motion_scale: $scale,
            motion_enabled: $enabled,
            floor_ms: $floor,
            semantic: ($m.semantic | with_entries(
                .value as $v
                | ($D[$v.duration] * $mult) as $scaled
                | (if $scaled < $floor then $floor else $scaled end | floor) as $clamped
                | .value = {
                    duration_ms: $clamped,
                    easing: $v.easing,
                    bezier: ($E[$v.easing] + [1, 1])
                  }
              ))
          }
    ' > "$out_dir/motion.json"

    return 0
}
