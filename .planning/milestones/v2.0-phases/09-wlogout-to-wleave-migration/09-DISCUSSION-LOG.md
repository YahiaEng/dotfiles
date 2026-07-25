# Phase 9: wlogout to wleave Migration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-25
**Phase:** 09-wlogout-to-wleave-migration
**Areas discussed:** Visual design direction, wlogout retirement policy, Render-and-look verification, Behavior & entry points

---

## Pre-discussion: pending-todo cross-reference

| Option | Description | Selected |
|--------|-------------|----------|
| Leave pending | Keep swaync-intrusive-overlapping out of Phase 9 | ✓ |
| Fold into Phase 9 | Add the swaync blur/overlap fix as extra scope | |

**User's choice:** Leave pending — swaync bug from Phase 8, unrelated to the power-menu migration.

---

## Visual design direction

### Overall look
| Option | Description | Selected |
|--------|-------------|----------|
| Center bar + frosted glass | Phase 6 layout, GTK4 transparent-window + Hyprland blur upgrade | ✓ |
| Faithful port | Reproduce Phase 6 look as-is, pure engine swap | |
| Fresh redesign | New power-menu design from scratch | |

### Frost structure
| Option | Description | Selected |
|--------|-------------|----------|
| One frosted card | Single translucent card containing the row (AGS popup language) | |
| Six frosted capsules | Each button its own translucent blurred pill (athena language) | ✓ |
| You decide | Claude picks at design time | |

### Backdrop
| Option | Description | Selected |
|--------|-------------|----------|
| Dim scrim | Subtle full-screen dim, current behavior | |
| No scrim | Desktop fully visible, capsules float | |
| Dim + hover labels | Dim scrim plus action label on hover | ✓ |

### Where chroma lives
| Option | Description | Selected |
|--------|-------------|----------|
| Neutral + hover accent | Neutral frost, @primary fill on hover (athena chroma=state) | |
| Per-action colors | Each capsule tinted with its own palette accent (floating rainbow) | ✓ |
| Neutral + danger marked | Neutral, hover @primary except @error on shutdown/reboot | |

### Color application (light-preset legibility)
| Option | Description | Selected |
|--------|-------------|----------|
| Tinted frost + on-color glyph | Container color at translucent alpha + on_container glyph (M3 pairing) | ✓ |
| Solid color fills | Solid @X fill + @on_X glyph (max legibility, loses frost) | |
| Solid on hover only | Neutral frost + colored glyphs at rest (the 08-16 failure mode) | |

### Hover feedback
| Option | Description | Selected |
|--------|-------------|----------|
| Brighten + border glow | Tint alpha up + brighter action-color border | ✓ (combined) |
| Scale up slightly | ~5-8% grow on hover | ✓ (combined) |
| Minimal | Label only | |

**User's choice:** Free-text combination — brighten + border glow + scale-up slightly.

### Hover label
| Option | Description | Selected |
|--------|-------------|----------|
| Below capsule + key hint | "Shutdown · S" teaches shortcuts | |
| Below capsule, name only | Just the action name | ✓ |
| Single shared label row | One fixed label line under the bar | |

### Open animation
| Option | Description | Selected |
|--------|-------------|----------|
| Quick fade-in | ~150-200ms fade | |
| No animation | Instant | |
| Pop/slide-in | Capsules scale-pop/slide into place | ✓ |

### Capsule geometry
| Option | Description | Selected |
|--------|-------------|----------|
| Rounded squares | ~96px squares, ~20-24px radius (AGS radius language) | ✓ |
| Circles | Fully circular dock-like capsules | |
| Wide pills | Horizontally stretched (e.g. 120×72) | |

### Entrance stagger
| Option | Description | Selected |
|--------|-------------|----------|
| Staggered wave | Left-to-right ~30-40ms offsets, <~350ms total | ✓ |
| All at once | Simultaneous pop | |
| Center-out | Symmetric bloom from center | |

### Scrim strength
| Option | Description | Selected |
|--------|-------------|----------|
| Claude tunes live | Start ~40% black, tune at visual checkpoint both modes | ✓ |
| Subtle (~25%) | Airy, less modal | |
| Strong (~55%) | Heavy focus | |

### Color mapping (6 actions, ~4 M3 hues)
| Option | Description | Selected |
|--------|-------------|----------|
| Semantic groups | Related actions share a hue; danger = @error family | |
| Six distinct hues | Derive 2 extra via GTK mix() (Phase 8 technique) | ✓ |
| You decide | Claude maps and validates contrast | |

### Glyph set
| Option | Description | Selected |
|--------|-------------|----------|
| Keep current set | Phase 6 cmap-verified glyphs carry over | |
| Refresh the set | New glyphs, cmap-verified per the established discipline | ✓ |
| You decide | Keep or swap per rendering at capsule size | |

### Capsule order
| Option | Description | Selected |
|--------|-------------|----------|
| Severity gradient | lock → logout → suspend → hibernate → reboot → shutdown | ✓ |
| Keep current order | Existing layout-file order | |
| Frequency-first | Most-used leftmost | |

### Rest-state border
| Option | Description | Selected |
|--------|-------------|----------|
| Hairline in action hue | 1px per-capsule hue at reduced alpha | ✓ |
| No border | Pure frost edges | |
| Neutral outline | Uniform @outline border | |

### Close animation
| Option | Description | Selected |
|--------|-------------|----------|
| Quick fade-out | ~100-150ms fade on dismiss | |
| Instant close | No exit animation | |
| Reverse stagger | Capsules pop out in reverse wave | ✓ |

### Keyboard-focus visual
| Option | Description | Selected |
|--------|-------------|----------|
| Same as hover | Identical treatment for keyboard focus | ✓ |
| Distinct focus ring | GTK-native a11y ring | |
| You decide | Per wleave's focus pseudo-classes | |

### Density
| Option | Description | Selected |
|--------|-------------|----------|
| Roomier (~24px) | Air between capsules, room for hover scale | ✓ |
| Keep 16px | Current density | |
| Generous (~32px+) | Widely spaced dock look | |

### Vertical position
| Option | Description | Selected |
|--------|-------------|----------|
| Optical center | ~45% from top | |
| True center | Exact vertical center | ✓ |
| Lower third | Dock-like ~65-70% | |

### Hover label animation
| Option | Description | Selected |
|--------|-------------|----------|
| Fade + slide up | Fades in sliding a few px up | ✓ |
| Instant | No animation | |
| Fade only | Opacity only | |

---

## wlogout retirement policy

### Retirement
| Option | Description | Selected |
|--------|-------------|----------|
| Full removal | Package, install.sh, stow.sh, template, layerrules all gone | ✓ |
| eww-style retirement | Configs removed, pacman package kept as fallback | |
| Keep both temporarily | Trial period, later cleanup phase | |

### Render target name
| Option | Description | Selected |
|--------|-------------|----------|
| Rename to wleave.css | Honest naming, one rename sweep | ✓ |
| Neutral: powermenu.css | Engine-agnostic name | |
| Keep wlogout.css | Zero churn, name lies | |

### AUR package
| Option | Description | Selected |
|--------|-------------|----------|
| wleave release | Pinned 0.7.1-1, eww-stable precedent | ✓ |
| wleave-git | Latest master | |
| Decide after research | Researcher checks changelog first | |

### Cutover timing
| Option | Description | Selected |
|--------|-------------|----------|
| After live approval | Ship wleave, pass gate, then remove wlogout (eww pattern) | |
| Atomic swap | One plan replaces everything at once | ✓ |
| You decide | Planner structures it | |

---

## Render-and-look verification

### Primary gate
| Option | Description | Selected |
|--------|-------------|----------|
| Human checkpoint + screenshots | Blocking checkpoint, grim evidence, user approves on sight | ✓ |
| Screenshot-only review | Agent self-assesses against spec | |
| Human checkpoint only | No screenshot artifacts kept | |

### Preset coverage
| Option | Description | Selected |
|--------|-------------|----------|
| Light + dark + live switch | One of each mode + hot re-theme proof | ✓ |
| Dark + light pair only | No live-switch demonstration | |
| Several presets | 4-5 representative presets walked | |

### Automated guard
| Option | Description | Selected |
|--------|-------------|----------|
| Yes, add to GTK4 list | wleave.css into theme-doctor non-empty-provider check | ✓ |
| Yes + launch smoke test | Provider check + headless-guarded launch test | |
| No new automation | Human gate is the guard | |

### Power-action UAT
| Option | Description | Selected |
|--------|-------------|----------|
| Spot-check safe ones | Live lock/suspend/logout; shutdown/reboot by string parity | ✓ |
| Full 6-action UAT | Live-fire everything incl. reboot cycles | |
| String parity only | No live action tests | |

---

## Behavior & entry points

### Toggle semantics
| Option | Description | Selected |
|--------|-------------|----------|
| Keep toggle | pgrep/pkill toggle like wlogout.sh | |
| Open-only | Keybind opens; Esc/click-away dismisses | ✓ |
| You decide | Per wleave single-instance behavior | |

### Per-button shortcuts
| Option | Description | Selected |
|--------|-------------|----------|
| Carry over as-is | l/e/u/h/s/r keep working | ✓ |
| Drop them | Mouse/arrows/Enter only | |
| Remap | New mnemonic set | |

### Confirmations
| Option | Description | Selected |
|--------|-------------|----------|
| No confirmation | Fire immediately (current behavior) | ✓ |
| Confirm destructive only | Shutdown/reboot ask once | |
| Confirm all | Every action confirms | |

### Entry-point rewiring
| Option | Description | Selected |
|--------|-------------|----------|
| Rename to wleave.sh | Honest name, three call sites repointed atomically | ✓ |
| Keep script name | wlogout.sh launches wleave | |
| Neutral name: powermenu.sh | Engine-agnostic script name | |

### Dismissal
| Option | Description | Selected |
|--------|-------------|----------|
| Esc + click-away | Both dismiss (AGS popup convention) | ✓ |
| Esc only | Scrim clicks inert | |
| You decide | Match wleave native support | |

### Multi-monitor
| Option | Description | Selected |
|--------|-------------|----------|
| Focused monitor only | Everything on the focused output | |
| All monitors | Scrim everywhere, capsules on focused | ✓ |
| You decide | Follow wleave native behavior | |

### Keybind
| Option | Description | Selected |
|--------|-------------|----------|
| Keep Super+Shift+Q | No bind change | ✓ |
| Change it | New chord through keybind-doctor gate | |

### Launch failure
| Option | Description | Selected |
|--------|-------------|----------|
| Notify on failure | notify-send error from wleave.sh guard | ✓ |
| Silent failure | Minimal wrapper | |
| Fallback to systemctl | walker dmenu fallback menu | |

---

## Claude's Discretion

- Exact scrim alpha, paddings, border widths, corner radius, easing curves, stagger timings (tuned live at the visual checkpoint)
- The two derived mix() hues and hue→action assignment, with per-preset contrast validation
- New glyph selection (cmap-verified) and glyph sizing
- Cursor shape, arrow-key navigation details
- Animation implementation mechanism (wleave native vs GTK4 CSS); degrade reverse-stagger exit to fast fade if it would delay power actions
- wleave layerrule specifics (namespace, blur, ignorealpha/ignorezero)

## Deferred Ideas

- `swaync-intrusive-overlapping.md` todo reviewed but not folded — swaync control-center fix stays pending, out of this phase's scope.
