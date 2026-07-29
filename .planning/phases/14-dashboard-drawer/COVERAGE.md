# API Coverage — Open-Meteo

> Full coverage by default. Opt-outs are explicit, reasoned decisions.

**Detector:** `api-coverage.cjs --json` → `detected: true` (signal: `api` / "Open-Meteo API docs (api.open-meteo.com) — forecast endpoint").
**Verdict:** this phase genuinely integrates one external API — Open-Meteo, the sole new external dependency in Phase 14 (D-29). Matrix below decided at plan time.

**Integration fence (D-29):** every INTEGRATE capability is reached through a single file, `modules/dashboard/WeatherBackend.qml`, so a provider swap stays a one-file change. No weather HTTP call may originate anywhere else in the drawer.

| capability | decision | reason |
|---|---|---|
| `/v1/forecast` — `current` block (temperature_2m, relative_humidity_2m, apparent_temperature, weather_code, wind_speed_10m, is_day) | INTEGRATE | D-37's current-conditions hero: large temp, condition, feels-like/humidity/wind |
| `/v1/forecast` — `hourly` block (temperature_2m, weather_code) | INTEGRATE | D-37's fixed 8-column hour strip |
| `/v1/forecast` — `daily` block (weather_code, temperature_2m_max, temperature_2m_min, sunrise, sunset) | INTEGRATE | D-37's 5-day row |
| Unit parameters (`temperature_unit`, `wind_speed_unit`, `precipitation_unit`) | INTEGRATE | D-31 — units are a user-editable key in the weather state file; the QML formatting layer is unit-aware |
| `timezone=auto` | INTEGRATE | Required for hourly/daily buckets to align to the user's local day (D-37's day-keyed forecast self-consistency) |
| `forecast_days` parameter | INTEGRATE | Bounded to 5 to match D-37's fixed 5-day row and keep the payload small |
| WMO weather-code vocabulary (~30 codes) | INTEGRATE | Mapped once to Material Symbols names in one pure function, reused across current/hourly/daily (RESEARCH "Don't Hand-Roll") |
| Geocoding API (`geocoding-api.open-meteo.com/v1/search`, city name → coords) | OPT-OUT | D-30 seeds city-level coordinates into a hand-editable state file; a graphical location picker is an explicitly deferred idea. Tracked for a follow-up phase — the endpoint is the natural backing call when that picker is built |
| GeoIP location fallback (`ip-api.com` / `ipinfo.io`, as the reference shell does) | OPT-OUT | Explicitly rejected by D-30 — a VPN silently shows the exit node's weather with no cue, and a GeoIP seed inside install would poison the container gate with the datacenter's city. RESEARCH Pitfall 7 exists to stop this being reintroduced by copying Caelestia |
| `minutely_15` sub-hourly resolution | OPT-OUT | D-32's ~15-min TTL cache makes sub-hourly resolution unobservable — strictly more payload for zero rendered difference |
| Weather alerts / warnings | OPT-OUT | D-29 records alerts as a known Open-Meteo weakness and explicitly out of scope; DASH-06 asks for current conditions + forecast only |
| Air Quality API (`air-quality-api.open-meteo.com`) | OPT-OUT | Not in DASH-06's enumeration; no widget slot exists in D-37's fixed canvas |
| Historical / Archive API | OPT-OUT | Trend/history is out of scope by the same boundary D-36 draws for Performance ("trends are btop's job") |
| Marine / Flood / Climate-projection APIs | OPT-OUT | No use case on a personal desktop dashboard; no DASH requirement references them |
| Elevation API | OPT-OUT | Coordinates come from a seeded state file, not derived terrain data |
| Explicit model selection (`models=` ensemble parameter) | OPT-OUT | D-29 accepted the auto model-aggregation behaviour (ECMWF/GFS/ICON auto-selected per location) after a user data-quality probe |
| API key / commercial tier (`customer-api.open-meteo.com`) | OPT-OUT | D-29 chose Open-Meteo *because* it is keyless — an API key would be uncommittable secret host-state and would break fresh-install reproducibility |

**Rate limit posture:** ~10k requests/day non-commercial. D-32 caps real usage far below this — the refresh timer runs only while the drawer is open, fetches only when the cache is older than the TTL, and issues zero requests on days the drawer never opens.
