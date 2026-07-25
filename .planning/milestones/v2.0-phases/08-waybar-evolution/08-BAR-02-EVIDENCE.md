<!-- Provenance: 08-10-PLAN.md, D-09 timeboxed BAR-02 spike + D-10 evidence requirement. Everything
     from the "## BAR-02" heading below is written to paste verbatim into 08-VERIFICATION.md as
     that requirement's verdict section — nothing above this line is load-bearing. Raw data behind
     every number here: .bar-02-spike-log.md (timestamped command/output log) and
     .bar-02-samples.tsv (raw duty-cycle samples), both in this directory. -->

## BAR-02

**Verdict:** DESCOPED

Date: 2026-07-14. Plan: 08-10.

### What was attempted

D-09's spike prescribed a 2px displacement every 15 minutes on static bar elements, via
`08-UI-SPEC.md`'s literal mechanism (CSS `margin` on `window#waybar`). Before spending the timebox
on that displacement question, this plan ran an actuation-cost pre-gate (K0-a) first, because
`08-RESEARCH.md` VERDICT 1 already carried a strong, HIGH-confidence prior against the UI-SPEC's
mechanism (`Alexays/Waybar#1533`: CSS margin does not reposition the layer-shell surface). That
pre-gate turned out to be decisive on its own, for a reason distinct from — and more fundamental
than — the UI-SPEC's specific mechanism choice:

- **The actuation path itself twitches and reflows, independent of what CSS payload it carries.**
  `bar-common.jsonc` fixes waybar's `on-sigusr2` action to `"reload"` (a FULL bar-config reload) —
  this is the ONLY signal any owner-driven CSS change (a jitter offset included) has available to
  reach the running bar. Firing that exact signal while the bar's computed state was unchanged (a
  no-op `reassert`) produced, confirmed reproducibly:
  - A real, visible flash on every actuation (2/2 independent `grim`+PIL/numpy bursts, peak
    mean-RGB delta ~65-80, decaying over ~400-500ms — visually confirmed by eye, not just numeric).
  - A real, transient window reflow on every actuation (3/3 independent `hyprctl clients -j` bursts
    at 30-50ms granularity: both tiled windows' `at`/`size` shift by exactly the bar's own reserved
    height (Δ37px) for one sample, then snap back on the very next sample).
- **M1 — CSS `margin` on `window#waybar`.** Not independently re-tested this session (moot — see
  below). `08-RESEARCH.md` VERDICT 1's finding stands, unresolved either way on the *content*
  question, because the actuation cost above disqualifies the mechanism before that question
  matters.
- **M2 — CSS `padding` on `window#waybar`.** Not tested, same reasoning — any padding-shift CSS
  still needs the identical SIGUSR2/reload actuation, already shown to twitch and reflow on its own.
- **M3 — rewriting bar-config `margin-*` keys + reloading.** Disqualified by design on three
  citations: (1) violates this repo's "runtime-only state overrides, never config rewriting"
  pattern (P7 D-26); (2) a full `reload` resets the bar to config-time visibility, which would
  resurrect a bar the owner had hidden (kill criterion #3 by definition); (3) recreating the
  layer-shell surface drops/re-adds the exclusive zone (kill criterion #2). Claim (3) is
  substantiated with a real measurement, not left as an argument: the K0-a reflow test above IS a
  bare SIGUSR2/`reload` — the same signal M3 would also require — and it measured exactly the
  transient reflow M3 predicted.
- **M4 — `reload_style_on_change`.** Deliberately not enabled: doing so would edit
  `bar-common.jsonc`, re-snapshotting the `waybar-equivalence-check` baseline that 08-08 was also
  re-snapshotting in this same wave. Noted as a lead for a future phase attacking this problem
  differently (see Residual Risk below), not evaluated further.

### Gate table

| Gate | D-09 criterion (verbatim) | Method | Instrument | Raw result | PASS/FAIL |
|---|---|---|---|---|---|
| K0-a (actuation cost) | *(pre-gate, not one of D-09's three, but decisive on its own)* | Fire the owner's `reassert` (bare SIGUSR2/`reload`) while the bar's computed state is unchanged; measure reflow + flash across the signal | `hyprctl clients -j` burst @ 30-50ms; `grim` burst + PIL/numpy mean-RGB diff | Reflow: Δy=37px/Δh=37px transient (3/3 runs). Flash: peak mean-RGB delta ~65-80, decays ~400-500ms (2/2 runs) | **FAIL** (both sub-costs) |
| K0-b (displacement viability) | *(pre-gate)* | Skipped per plan's own fast-path instruction once K0-a fired | N/A | Not run — mechanism-moot, not mechanism-unavailable (see distinction in spike log) | **SKIPPED (moot)** |
| K1 — perceptible twitch | "the movement is perceptible as a twitch" | (a) fold in K0-a's flash finding; (b) FAIL-CLOSED default absent a recorded human PASS | (a) K0-a's grim/PIL instrument; (b) plan's own FAIL-CLOSED rule | (a) real, reproducible flash on every actuation; (b) no human perception pass obtained — this plan executes autonomously with no live interactive channel for an unannounced-trial perception test | **FAIL** (two independent grounds) |
| K2 — reflows a window | "it reflows any window" | `hyprctl clients -j` `at`/`size` per window address, polled across the actuation signal | `hyprctl clients -j` + `jq`, 30-50ms burst | Real, reproducible transient reflow, 3/3 runs (Δ37px both windows) | **FAIL** |
| K3 — coordination beyond "don't jitter while hidden" | "it needs to coordinate with the visibility owner beyond 'don't jitter while hidden'" | Structural four-part falsifier, evaluated by design inspection | N/A (design-only; K1/K2 already end the spike before code would be written) | A jitter verb COULD in principle satisfy all four parts (reuse owner's exact CLI/CSS-write/signal shape) — not independently decisive since K1/K2 already fail on the actuation mechanism itself | **N/A — moot** (not exercised against real code; not claimed as PASS or FAIL) |

### Which gate fired

**K0-a (actuation-cost pre-gate) fired, on both of its measured sub-costs (flash and transient
reflow).** This is explicitly NOT "K0-b: mechanism unavailable" — that framing is reserved for the
case where no CSS trick moves any content. Here the situation is different and more fundamental:
the mechanism's *actuation itself* — the only signal any owner-driven CSS change has to reach the
running bar — already, independently of what CSS payload it carries, produces a real visible flash
and a real transient window reflow on every single invocation. This directly and independently
fires D-09 kill criterion #1 (perceptible twitch, both via the measured flash and via the
FAIL-CLOSED no-obtainable-human-pass default) and kill criterion #2 (reflows a window). Kill
criterion #3 is moot given #1 and #2 already end the spike. The 90-minute timebox was **not**
exceeded — the spike concluded in ~4 minutes of real measurement (19:44:16Z start, 19:48:10Z
conclusion, against a 21:14:16Z deadline): an early, decisive outcome produced by real evidence,
not a rushed shortcut around gathering it.

### Standing hypothesis evaluation

*"D-01's auto-hide plus D-06's low-luminance styling may already remove most of the exposure
pixel-shift targets."*

**Luminance delta (Part B, measured against the real running bar, BEFORE/AFTER the D-06 trim,
Rec.709 relative luminance on linearised sRGB, mean + 99th-percentile peak):**

| Preset | Mean BEFORE | Mean AFTER | Mean Δ | Peak99 BEFORE | Peak99 AFTER | Peak99 Δ |
|---|---|---|---|---|---|---|
| Dark (catppuccin) | 0.073396 | 0.044569 | **-39.27%** | 0.460594 | 0.466843 | **+1.36%** |
| Light (catppuccin-latte) | 0.746595 | 0.722990 | -3.16% | 0.870290 | 0.790389 | -9.18% |

Measured via a surgical two-rule swap (`window#waybar` background/border-bottom in
`style-full.css`; `#workspaces button.active` in `waybar-modules.css` — confirmed via `git diff`
against the pre-trim commit that these are the ONLY two rules that changed in either file) against
the live `full`-layout bar, geometry read live from `hyprctl layers -j` (`x=10 y=6 w=2540 h=40`),
never hardcoded. Both anomalies found are reported, not suppressed: the light preset did NOT show
the risk the plan specifically flagged (a translucent bar raising mean luminance over a light
backdrop) — both its mean and peak decreased. The dark preset showed a DIFFERENT, unanticipated
anomaly instead: peak (99th-percentile) luminance slightly increased despite a large mean
reduction, most plausibly because peak is dominated by bright glyph/icon pixels the trim never
touches, computed as a percentile over a now-darker overall distribution — a genuine limitation of
a whole-region proxy, stated rather than hidden.

**Exposure ratio (Part A): UNMEASURED.** A real 5-second sampling loop ran against the owner's own
`status` output for 187 samples over 15.53 minutes (2026-07-14 19:44:44Z–20:00:19Z) — real,
honestly-collected data, showing `visible` on 100% of samples (zero `hidden-idle`/`hidden-hard`
readings). This is reported as UNMEASURED rather than as a ratio of 1.0 for two independent
reasons, both stated in the plan itself: it falls short of the required ≥60-minute/≥720-sample
floor (187/720 collected), AND it fails the plan's own "genuine mixed activity" validity test on
its face — a window with zero idle stretches at all is exactly as unrepresentative as an
all-idle window would have been in the other direction, and the plan explicitly forbids treating
either degenerate case as evidence. No synthetic input was injected to manufacture a transition
either way. The idle timeout this would have been measured under, had the session reached
validity: 120s (`08-04-SUMMARY.md` D-05).

**Overall verdict: PARTIALLY SUPPORTED** (one of exactly three permitted labels). The dark-preset
mean luminance reduction is real and substantial (-39.27%) and directly on-target for D-06's
stated intent — but the dark-preset peak increase (+1.36%) and the entirely-unmeasured exposure
ratio mean an unqualified SUPPORTED would overclaim what was actually measured, and dismissing the
dark-preset mean result as NOT SUPPORTED would equally overclaim in the other direction. **These
are exposure/luminance proxies, not burn-in measurements** — nobody can prove a burn-in outcome
inside one phase, and this plan does not claim to.

### Residual risk, and what would change the verdict

Because the exposure ratio is UNMEASURED (not confirmed low), the residual OLED risk from a
statically-lit bar cannot be characterized as "mostly mitigated" on this plan's evidence alone —
it rests on D-01/BAR-01's auto-hide actually engaging during real usage (which 08-04-SUMMARY.md
independently documented firing correctly, unprompted, on a different occasion) plus the luminance
reduction measured here (real on the dark-preset mean, not on dark-preset peak). Pixel-shift itself
remains entirely unmitigated — no displacement mechanism was shipped, and the actuation-cost
finding here suggests it may not be viable at all through waybar's current signal model. What
would change this verdict:
- **An actuation path that updates a mapped waybar surface's CSS with zero reflow and zero visible
  flash.** This is the concrete, load-bearing gap this plan's K0-a finding surfaces: it is a more
  fundamental blocker than "does margin/padding shift content," and a future phase would need to
  solve it before M1/M2's own displacement question is even worth re-asking. `waybar(5)`'s
  `reload_style_on_change` (noted as M4 above, deliberately not enabled here) is one candidate
  worth spiking specifically for whether it avoids the full-reload flash/reflow this plan measured
  — untested here only because enabling it would have re-snapshotted the equivalence baseline
  08-08 was also touching in this same wave.
- **A validated, ≥60-minute, genuinely mixed-usage exposure-ratio sample**, obtained in a context
  where a real human is actively alternating between working and stepping away (this plan's
  15-minute sample happened to observe continuous input for its entire span and could not be
  extended to validity within a single autonomous execution).
- **A drawing surface with real per-frame animation control** (outside waybar/GTK3 entirely) — the
  structural reason RESEARCH VERDICT 1 and this plan's K0-a both point at: GTK3 CSS transitions
  animate *properties of a mapped widget*, not the reload/rebuild cycle a config-level CSS change
  currently requires.

### Reproduce

- K0-a reflow/flash bursts: `hyprctl clients -j | jq -c '[.[] | {address, at, size}]'` polled at
  30-50ms across `hypr/.config/hypr/scripts/waybar-visibility.sh reassert`; `grim -g "0,0 2560x37"`
  bursts + inline `python3` (PIL + numpy) mean-RGB diff across the same signal. Raw captures:
  `.bar-02-spike-log.md` (K0-a section) cites every number verbatim from
  `clients-burst{,2,3}.log`, `control-burst.log`, `k0a-{pre,post}-*.png`, `k0a-r2-{pre,post}-*.png`
  (scratchpad — referenced, not committed).
- Luminance BEFORE/AFTER: geometry via `hyprctl layers -j | jq -r '.[].levels[]?[]? | select(.namespace=="waybar")'`;
  capture via `grim -g "<geometry>"`; metric via the inline Python script recorded in
  `.bar-02-spike-log.md` Part B (Rec.709 on linearised sRGB, mean + `numpy.percentile(Y, 99)`).
  BEFORE state reproduced via `git diff b2423b4^ -- waybar/.config/waybar/style-full.css
  waybar/.config/waybar/waybar-modules.css` (identifies the exact two rules to swap), then
  `pkill -SIGUSR2 waybar`, capture, `git checkout --` both files immediately.
- Exposure sampling: `hypr/.config/hypr/scripts/waybar-visibility.sh status`, polled every 5s;
  raw output in `.bar-02-samples.tsv` (this directory).
- Full raw command/output/timestamp trail for every number above:
  `.planning/phases/08-waybar-evolution/.bar-02-spike-log.md`.
