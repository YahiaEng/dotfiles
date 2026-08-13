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

# 14-04 render-gate fix: Hyprland's `hl.animation()` rejects any `speed`
# field above 100.00 — confirmed live via `hyprctl configerrors` after
# switching to the `lively` motion-scale preset:
# `hl.animation("borderangle"): field "speed": value 125.00 is more than
# the maximum of 100.00`. `border-rotate`'s 10000ms duration_ms is already
# at exactly this ceiling at the "normal" (1.0x) multiplier — D-09's
# existing floor_ms clamp only protects the LOW end, so "lively"'s 1.25x
# multiplier pushed it to 12500ms/speed 125.00 with nothing to catch it
# before it reached a Hyprland-consumed field, a pre-existing gap in the
# motion pipeline that this plan's segmented row was the first thing in
# this repo to actually press. Mirrors D-09's WARN-never-fail posture: the
# emitted speed is clamped to this ceiling (never dropped, never a hard
# failure) and a WARN line records every clamp event through the same
# GENERATE_LOG channel the floor clamp already uses.
MOTION_HYPR_MAX_SPEED=100.00

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

    # 13-01 Task 3G: extend validation to the new .indicators top-level
    # category — same validate-before-any-write discipline, same
    # diagnose-to-stderr shape. (The sibling A/B curve-comparison category
    # and its validation were removed in plan 13-07 alongside the D-21
    # toggle.)
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

    return 0
}

# theme_engine_render_motion_files <tmp_dir>
# Renders motion.json, gtk-4.0-motion.css and hyprland-tokens.lua into the
# tmp render tree — same call shape as theme_engine_render_font_files. Reads
# the motion-scale axis, resolves its multiplier/animations_enabled from
# motion.json's OWN scales table (D-21 — the multiplier table lives in
# data, not here), validates BEFORE any write, then emits all targets
# from one shared jq computation so they can never disagree with each
# other or with the WARN pass below.
#
# 13.1-10: the hyprland-motion.conf (hyprlang) emitter that used to write
# here alongside the Lua token merge was retired once the operator
# resolved Task 2's one-way decision as retire-now — the merged
# hyprland-tokens.lua table (theme_engine_render_hypr_tokens, below) is now
# the sole Hyprland-side motion output. See
# 13.1-EQUIVALENCE-REPORT.md's "Decision (Task 2)" section.
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

    # 13-01 Task 3H: the two TSVs the semantic-scale resolution feeds into
    # the Hyprland writer's $motion_speed_* families below. (The sibling
    # per-slot curve variable family, driven by the D-21 A/B
    # curve-comparison toggle, was removed in plan 13-07 — the six
    # feel-changing slots now reference their settled curve names as
    # literals in animations.conf instead.)
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

    # ── 1. Hyprland target: the merged Lua token table (D-02/D-05, Phase
    #    13.1) — ONE generated file carrying BOTH colours and motion as
    #    DATA, not executable config syntax. This is now the SOLE
    #    Hyprland-side motion/colour output: the sibling hyprlang
    #    hyprland-motion.conf emitter that used to write
    #    $motion_enabled/$motion_speed_*/an `animations {}` bezier block
    #    here was retired in 13.1-10 once the operator resolved Task 2's
    #    one-way decision as retire-now (see
    #    13.1-EQUIVALENCE-REPORT.md's "Decision (Task 2)" section). Reuses
    #    this function's already-validated
    #    $animations_enabled/$speed_semantic/$speed_indicators/$MOTION_JSON
    #    locals via bash's dynamic scoping, same pattern as
    #    theme_engine_render_motion_scss below. ─────────────────────────
    theme_engine_render_hypr_tokens "$out_dir" || return 1

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
    #
    # `indicators` is emitted here as well as to the Hyprland target (DASH-10).
    # It was previously Hyprland-only, so a QML surface had no way to read
    # `border-rotate` at all — the drawer's animated gradient border needs the
    # SAME rotation period Hyprland's `borderangle` uses, or the two visibly
    # drift apart on screen.
    #
    # Indicators get the same multiplier and the same floor_ms clamp as the
    # semantic pairs, PLUS the Hyprland speed ceiling ($hypr_ceiling_ms, the
    # ms form of $MOTION_HYPR_MAX_SPEED). The ceiling matters because
    # `border-rotate` sits at exactly 10000ms — the ceiling — at the 1.0x
    # multiplier, so at `lively` (1.25x) the token resolves to 12500ms while
    # Hyprland itself clamps to 10000ms. Emitting the unclamped number to QML
    # would make the drawer's border rotate slower than every window border on
    # screen. Applying the ceiling to the whole bucket is a deliberate no-op
    # for the other two indicators (blink-slow 1000ms, blink-fast 500ms, both
    # an order of magnitude below it) and keeps one rule rather than a
    # per-token carve-out.
    local hypr_ceiling_ms
    hypr_ceiling_ms="$(awk -v s="$MOTION_HYPR_MAX_SPEED" -v d="$MOTION_HYPR_SPEED_DIVISOR_DS" 'BEGIN{printf "%d", s*d}')"
    # G-15-1: emit the resolved multiplier itself as a top-level number,
    # alongside motion_scale/motion_enabled. QML needs the NUMBER, not just
    # the scale NAME, so a continuous loop-period token (e.g. Motion.qml's
    # `ambientDuration`) can divide the multiplier back out and never
    # shrink its period when the multiplier drops below 1.0 — the
    # accessibility ("reduced") preset must not make an indicator faster.
    # $mult is already in scope from this function's own --argjson binding
    # above; nothing else in this block changes (the semantic/indicators
    # clamping arithmetic stays exactly as it was).
    jq -n --argjson mult "$multiplier" --argjson floor "$floor_ms" \
        --argjson ceil "$hypr_ceiling_ms" \
        --arg scale "$scale" --argjson enabled "$animations_enabled" \
        --slurpfile src "$MOTION_JSON" '
        $src[0] as $m
        | $m.durations as $D | $m.easings as $E
        | {
            motion_scale: $scale,
            motion_enabled: $enabled,
            motion_multiplier: $mult,
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
              )),
            indicators: (($m.indicators // {}) | with_entries(
                .value as $v
                | ($v.duration_ms * $mult) as $scaled
                | (if $scaled < $floor then $floor else $scaled end) as $floored
                | (if $floored > $ceil then $ceil else $floored end | floor) as $clamped
                | .value = {
                    duration_ms: $clamped,
                    easing: $v.easing,
                    bezier: ($E[$v.easing] + [1, 1])
                  }
              ))
          }
    ' > "$out_dir/motion.json"

    # ── 4. GTK3 target: a sass PARTIAL (leading underscore — D-01/T-13-06).
    #    GTK3 3.24.52 has no CSS custom-property mechanism at all, so unlike
    #    the GTK4 :root writer above (which every GTK4/QML surface can read
    #    live via var()), this fourth target is consumed at COMPILE time by
    #    theme_engine_compile_gtk3_stylesheets (called right after this
    #    function returns, from theme_engine_generate) via `@use "motion" as
    #    m;` with --load-path pointed at this same tmp tree. Called from
    #    inside THIS function (not a separate top-level call site in
    #    generate.sh) specifically so it reuses $resolved/$multiplier/
    #    $floor_ms/$MOTION_JSON already computed above — bash's dynamic
    #    scoping makes every one of those visible here with no re-validation
    #    and no risk of the two writers ever disagreeing about a value.
    theme_engine_render_motion_scss "$out_dir"

    return 0
}

# _hypr_lua_quote_string <raw>
# Quotes a raw string value as a Lua string literal, escaping backslashes
# FIRST (order matters — escaping the quote first would double-escape the
# backslash the quote-escape itself just inserted) and then double-quotes.
# This is the ONLY path any upstream-sourced value may reach
# hyprland-tokens.lua through (T-13.1-01) — never printf/echo a raw value
# straight into Lua source text; unlike hyprlang's `$var = value` (no
# code-execution semantics at all), a .lua file is directly executed.
_hypr_lua_quote_string() {
    local raw="$1"
    raw="${raw//\\/\\\\}"
    raw="${raw//\"/\\\"}"
    printf '"%s"' "$raw"
}

# _hypr_clamp_speed_ms <token> <ms>
# Converts a resolved duration (ms) to Hyprland's `speed` unit
# ($MOTION_HYPR_SPEED_DIVISOR_DS ms per unit) and ceiling-clamps it to
# $MOTION_HYPR_MAX_SPEED before it ever reaches hyprland-tokens.lua —
# `hl.animation()` hard-rejects a speed field above that value (D-09-style
# fix, see $MOTION_HYPR_MAX_SPEED's header comment for the live
# `hyprctl configerrors` observation that found this). Mirrors the floor
# clamp's WARN-never-fail posture: a clamp event logs one line through
# $GENERATE_LOG (same sanitization discipline as every other warning this
# file already emits) and the render still completes.
_hypr_clamp_speed_ms() {
    local token="$1" ms="$2"
    local speed
    speed="$(awk -v ms="$ms" -v d="$MOTION_HYPR_SPEED_DIVISOR_DS" 'BEGIN{printf "%.2f", ms/d}')"
    if awk -v s="$speed" -v max="$MOTION_HYPR_MAX_SPEED" 'BEGIN{exit !(s > max)}'; then
        local warn_msg
        warn_msg="WARN — motion.speed.${token} (${speed}) exceeds Hyprland's ${MOTION_HYPR_MAX_SPEED} animation-speed ceiling; clamped to ${MOTION_HYPR_MAX_SPEED}."
        warn_msg="$(printf '%s' "$warn_msg" | head -c 200 | tr -d '\000-\011\013\014\016-\037')"
        printf '%s\n' "$warn_msg" >> "${GENERATE_LOG:-/dev/null}"
        speed="$MOTION_HYPR_MAX_SPEED"
    fi
    printf '%s' "$speed"
}

# theme_engine_render_hypr_tokens <out_dir>
# Merges the matugen-rendered colour fragment ($out_dir/hyprland-colors.lua,
# written by the additive [templates.hyprland_lua] matugen target into this
# SAME tmp render tree, if present) with the motion resolution
# theme_engine_render_motion_files already computed — the SAME
# $animations_enabled/$speed_semantic/$speed_indicators/$MOTION_JSON locals
# declared `local` in that function are visible here via bash's dynamic
# scoping, exactly like theme_engine_render_motion_scss below — into ONE
# generated Lua table: $out_dir/hyprland-tokens.lua (D-02/D-05).
#
# D-13's fresh-install corollary: a missing colour fragment (the seed-only
# render path stow.sh uses, where matugen has never run) degrades to an
# EMPTY colors table, not a failure — the motion half is always populated
# regardless, so the file itself is always written and is always valid Lua.
#
# Called from theme_engine_render_motion_files as its sole Hyprland-side
# target (13.1-10: the sibling hyprland-motion.conf hyprlang emitter that
# used to be written first was retired once Task 2's decision resolved
# retire-now). Deletes the consumed colour fragment from the tmp tree
# before returning so it never reaches ~/.local/state/theme/ and never
# needs its own contract.json entry.
theme_engine_render_hypr_tokens() {
    local out_dir="$1"
    local colors_fragment="$out_dir/hyprland-colors.lua"
    local out_file="$out_dir/hyprland-tokens.lua"

    {
        echo "-- Generated by theme-engine; do not edit manually (D-02/D-05)."
        echo "-- colors: matugen's hyprland-colors.lua fragment, merged here by"
        echo "-- theme_engine_render_hypr_tokens (theme-engine/lib/motion.sh)."
        echo "-- motion: the SAME resolution gtk-4.0-motion.css emits —"
        echo "-- the targets can never disagree about which values exist (D-05)."
        echo "return {"
        echo "    colors = {"
        if [[ -f "$colors_fragment" ]]; then
            # Parse the matugen-rendered fragment's `key = "value",` lines
            # and re-emit through the quoting writer above — never trust
            # the fragment's own quoting, re-derive it from the raw string
            # content every time (T-13.1-01).
            local _cline
            while IFS= read -r _cline; do
                if [[ "$_cline" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*\"(.*)\",?[[:space:]]*$ ]]; then
                    printf '        %s = %s,\n' "${BASH_REMATCH[1]}" \
                        "$(_hypr_lua_quote_string "${BASH_REMATCH[2]}")"
                fi
            done < "$colors_fragment"
        fi
        echo "    },"
        echo "    motion = {"
        printf '        enabled = %s,\n' "$animations_enabled"
        echo "        speed = {"
        # motion.speed.<token> — one entry per $motion_speed_<sem_token>
        # variable (key name = the variable name with the motion_speed_
        # prefix stripped, e.g. $motion_speed_standard -> speed.standard),
        # and one entry per $motion_speed_indicator_<ind_name> variable
        # (key name = indicator_<ind_name>, e.g.
        # $motion_speed_indicator_border_rotate -> speed.indicator_border_rotate).
        # Reuses the SAME awk %.2f conversion and divisor the retired
        # hyprland-motion.conf writer used (13.1-10) — kept identical so
        # this value never silently drifts from what that hyprlang emitter
        # produced while it existed. Ceiling-clamped to
        # $MOTION_HYPR_MAX_SPEED (see that constant's header comment) since
        # this is the only one of the four render targets whose consumer
        # (Hyprland's `hl.animation()`) hard-rejects a speed above 100.00;
        # GTK4/QML/SCSS keep the true unclamped ms value because they have
        # no such ceiling.
        while IFS=$'\t' read -r sem_token sem_ms; do
            [[ -z "$sem_token" ]] && continue
            printf '            %s = %s,\n' "$sem_token" \
                "$(_hypr_clamp_speed_ms "$sem_token" "$sem_ms")"
        done <<< "$speed_semantic"
        while IFS=$'\t' read -r ind_name ind_ms; do
            [[ -z "$ind_name" ]] && continue
            printf '            indicator_%s = %s,\n' "$ind_name" \
                "$(_hypr_clamp_speed_ms "indicator_$ind_name" "$ind_ms")"
        done <<< "$speed_indicators"
        echo "        },"
        echo "        curves = {"
        # motion.curves.<key> — one entry per .easings key in $MOTION_JSON,
        # shaped { type = "bezier", points = { {x0,y0}, {x1,y1} } } from the
        # SAME four floats the retired hyprland-motion.conf writer's (13.1-10)
        # `bezier = motion-<key>, x0, y0, x1, y1` line used to emit — structural
        # change (nested points array), not a value change. Bracket-string
        # keys (never bare identifiers) because easing names carry hyphens
        # (e.g. "standard-decelerate"), which is not valid Lua identifier
        # syntax as a bare table key.
        jq -r '.easings | to_entries[] |
            "            [\"\(.key)\"] = { type = \"bezier\", points = { {\(.value[0]), \(.value[1])}, {\(.value[2]), \(.value[3])} } },"' \
            "$MOTION_JSON"
        echo "        },"
        echo "    },"
        echo "}"
    } > "$out_file"

    rm -f "$colors_fragment"

    return 0
}

# theme_engine_render_motion_scss <out_dir>
# Writes $out_dir/_motion.scss — the sass partial GTK3 surfaces consume via
# `@use "motion" as m;` (D-01). Deliberately called from INSIDE
# theme_engine_render_motion_files (see call site above) so it shares that
# function's already-validated $resolved/$multiplier/$floor_ms/$MOTION_JSON
# locals via bash's dynamic scoping — same TSV-driven loop shape as the GTK4
# :root writer immediately above it in this file, same unconditional
# `.easings | to_entries[]` emit so the two writers can never disagree about
# which easings exist (D-05/one-source-of-truth), same multiplier/floor
# clamp on indicator durations as the semantic pairs so `reduced`/`lively`
# reach GTK3 indicators too.
theme_engine_render_motion_scss() {
    local out_dir="$1"

    {
        # $motion-duration-<token> — one per .semantic entry (SCSS
        # identifiers allow hyphens natively, unlike Hyprland's
        # $motion_speed_* variables, so no gsub("-","_") is needed here).
        while IFS=$'\t' read -r token _easing ms _clamped; do
            [[ -z "$token" ]] && continue
            printf '$motion-duration-%s: %sms;\n' "$token" "$ms"
        done <<< "$resolved"

        # $motion-easing-<name> — every declared easing, unconditionally.
        jq -r '
            .easings | to_entries[] |
            "$motion-easing-\(.key): cubic-bezier(\(.value | join(", ")));"
        ' "$MOTION_JSON"

        # $motion-indicator-<name>-duration / -easing — one pair per
        # .indicators entry, scaled/clamped by the SAME multiplier/floor as
        # the semantic pairs above.
        jq -r --argjson mult "$multiplier" --argjson floor "$floor_ms" '
            .easings as $E
            | (.indicators // {}) | to_entries[]
            | .key as $k | .value as $v
            | ($v.duration_ms * $mult) as $scaled
            | (if $scaled < $floor then $floor else $scaled end | floor) as $clamped
            | ($E[$v.easing] | join(", ")) as $bez
            | "$motion-indicator-\($k)-duration: \($clamped)ms;\n$motion-indicator-\($k)-easing: cubic-bezier(\($bez));"
        ' "$MOTION_JSON"
    } > "$out_dir/_motion.scss"

    return 0
}

# GTK3_SCSS_TARGETS — "<abs-source-path>:<output-name>" pairs consumed by
# theme_engine_compile_gtk3_stylesheets below (D-01/D-04). An array rather
# than inline invocations so a future stylesheet family can append rows
# without restructuring that function (D-18 soak-integrity note: this file
# also emits the Hyprland motion target the 13-01 soak measures, and this
# array is the only thing that plan changes in it). Seeded with exactly one
# row in 13-02; a six-row bar-layout family that briefly lived here was
# retired along with the surface that owned it.
GTK3_SCSS_TARGETS=(
)

# theme_engine_compile_gtk3_stylesheets <tmp_dir>
# Compiles every GTK3_SCSS_TARGETS row's repo-authored .scss into the SAME
# tmp render tree theme_engine_render_motion_files just wrote
# $tmp$STATE_DIR/_motion.scss into (D-34: sass runs inside
# theme_engine_generate, before commit.sh's atomic promote, so a failed
# compile leaves the live state dir byte-unchanged). --load-path points at
# $tmp$STATE_DIR specifically — never the live state dir — so a compile
# always resolves against the partial THIS SAME run rendered, never a
# stale one. Returns non-zero on the first failing compile; sass's stderr
# is captured into GENERATE_LOG using the exact discipline generate.sh
# already applies to matugen's stderr (T-13-08) — theme-apply's existing
# head -c 200 | tr -d sanitization pass is what keeps it out of a
# notification unsanitised, not this function.
#
# Three details are non-negotiable (T-13-06/WLOG-01, verified directly on
# this machine — see 13-02-PLAN.md Task 2):
#   --no-charset     a bare invocation emits a charset at-rule as line 1;
#                     GTK3's CssProvider then discards the ENTIRE
#                     stylesheet, not just that line, and does so silently.
#   --no-source-map  suppresses a sourceMappingURL comment and a stray
#                     .map file that would otherwise land in the state dir
#                     on every compile and break the contract manifest.
#   --load-path       must be $tmp$STATE_DIR (the tmp tree), never the live
#                     state dir.
theme_engine_compile_gtk3_stylesheets() {
    local tmp="$1"
    local out_dir="$tmp$STATE_DIR"
    mkdir -p "$out_dir"

    local row src out
    for row in "${GTK3_SCSS_TARGETS[@]}"; do
        src="${row%%:*}"
        out="${row##*:}"

        if [[ ! -f "$src" ]]; then
            echo "motion.sh: GTK3 sass source not found: $src" >&2
            return 1
        fi

        if ! sass --no-charset --no-source-map --load-path="$out_dir" \
                "$src" "$out_dir/$out" 2>>"${GENERATE_LOG:-/dev/null}"; then
            echo "motion.sh: sass compile failed for $src -> $out (see ${GENERATE_LOG:-stderr} for the compiler's diagnostic)" >&2
            return 1
        fi
    done

    return 0
}
