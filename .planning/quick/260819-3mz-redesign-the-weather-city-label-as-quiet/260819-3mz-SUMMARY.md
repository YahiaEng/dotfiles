---
quick_id: 260819-3mz
date: 2026-08-19
mode: quick
status: complete
one_liner: city label rebuilt as quiet typography inside the hero column, and the coordinates corrected from Cairo to Alexandria — the forecast itself had been the wrong city's
---

# Quick Task 260819-3mz — Summary

## The coordinates were wrong, not just the label

`weather.json` held `30.04, 31.24` — Cairo. The eyebrow was faithfully reporting
what it was told. The forecast had been ~180 km off the whole time: Alexandria
measured **25.6 °C** against the **28.5 °C** on screen.

Alexandria's coordinates were resolved by forward geocoding (Open-Meteo search,
the endpoint that IS forward-capable): `31.20176, 29.91582`, population 5.26 M —
unambiguously the Egyptian one among five candidates. Round-tripped through the
exact Nominatim call the shell makes: returns `Alexandria`.

**This retroactively justified the geocode decision.** Alexandria's timezone is
also `Africa/Cairo`, so the zero-network timezone fallback would have printed
"Cairo" while the operator sat in Alexandria. The case raised as hypothetical
during design — "someone in Giza also gets Cairo" — was the operator's actual
situation.

## The redesign, diagnosed against the measured type scale

Operator reported *wrong place or size entirely* and *it floats / feels detached*.

Type scale measured: **display 32 / heading 20 / body 16 / label 12**. The label
shipped at `fontLabel` — the smallest step in the entire scale — sitting under a
32 px number. Structurally it was its own `Row` with `anchors.horizontalCenter`,
centred across the whole hero including the condition glyph, aligned to nothing
below it.

Both halves of the complaint were mechanical, not matters of taste.

**Now:** the city is the first child of the temperature/condition `Column`,
sharing that column's left edge with `25°` and `Mainly clear`. Glyph dropped,
uppercase dropped, `fontBody`, one `onSurfaceVariant` role.

The glyph and uppercase were mine to begin with and both were unprecedented: no
`toUpperCase`, `letterSpacing` or `font.capitalization` exists in any other `.qml`
in this repo. The primary-coloured glyph beside muted text read as two unrelated
things.

Preserved: hidden when there is no label (never a placeholder dash), and therefore
zero height — a QML `Column` skips non-visible children, so the tab's advisory
size formula is still untouched.

## The seed, and a privacy trap avoided

`stow.sh` seeded Cairo, so a fresh install would not reproduce the operator's real
setup — it would silently serve another city's weather.

The seed's own comment (D-30) states the repo is public and that precise
coordinates committed to git are self-doxxing. The full-precision value
(`31.20176, 29.91582`, ~1 m) was about to go into a public repo. **Seeded at two
decimals instead** — `31.20, 29.92`, city centroid, matching the existing style —
and verified that the coarse value still reverse-geocodes to "Alexandria" rather
than a suburb. The operator's live `~/.local/state/theme/` copy keeps full
precision; that file is never git-tracked, which the same comment says explicitly.

## A transient gate result worth recording

`quickshell-doctor` read **25 passed / 3 failed** immediately after the QML edit,
then **28 / 0** on every re-run. Its checks probe the *live* shell, and the edit
had just triggered a hot reload — monitor and panel counts were momentarily in
flux. The line that looked like a failure was a `pre[...]` precondition inside a
check that ultimately passes. Re-run twice to confirm before believing a live-probe
failure that arrives seconds after a hot reload.

## Gates
qmllint exit 0 · `bash -n stow.sh` OK · colour-lint 146/0 · motion-lint 293/0 ·
quickshell-doctor 28/0 (stable across two runs) · theme-doctor 586/0 after the
docs commit.

## Files
- `quickshell/.config/quickshell/modules/dashboard/WeatherTab.qml` — label moved into the hero column, glyph and uppercase removed, fontLabel -> fontBody
- `stow.sh` — seed Cairo -> Alexandria at city-centroid precision, with the reason recorded in the existing comment's voice
- `~/.local/state/theme/weather.json` (host state, not repo) — coordinates corrected, written atomically

Commit: `19fa106`
