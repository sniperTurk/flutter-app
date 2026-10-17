# Google hava verisi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hava Durumu weather comes from the Google Weather API first and falls back to MET Norway; the Hava card note names the source and the Rüzgâr card shows a read-only wind note.

**Architecture:** New `GoogleWeatherProvider` (port `WeatherProvider`), a `FallbackWeatherProvider` (Google → MET) wired in `ToolsServices.production()`. `WeatherObservation` gets a `source` enum (default `other`, so every existing constructor still compiles). A pure function builds the wind note; the page keeps it in memory like `_weatherStatus`.

**Tech Stack:** Flutter 3.47.2, package:http (MockClient in tests).

**Spec:** owner task 2026-10-17 20:44 (task message, decisions 20:13–20:44).

## Global Constraints

- Key: `String.fromEnvironment('GOOGLE_MAPS_IOS_API_KEY')`, never committed, never logged; header `X-Ios-Bundle-Identifier: com.sniperturk.sniperTurk`; empty key → no request.
- Endpoint `https://weather.googleapis.com/v1/currentConditions:lookup`, `location.latitude`, `location.longitude`, `unitsSystem=METRIC`; coordinates rounded to 2 decimals as MET (`WeatherPolicy.roundCoordinate`).
- Google METRIC wind speed is km/h (`KILOMETERS_PER_HOUR`) → m/s = km/h ÷ 3,6. Pressure `airPressure.meanSeaLevelMillibars` (1 mb = 1 hPa), `PressureKind.seaLevel`.
- Hava note: `(Google, HH:MM)` for Google; MET sentence unchanged.
- Wind note: `"<Kaynak> rüzgâr verisi (HH:MM): <yön>dan, <derece>°, <hız> m/s. Rüzgâr yönünü siz seçin."`, 8 Turkish directions, comma decimal; no clock-hour conversion, no azimuth.
- No layout/spacing change, no new saved field, no other pages.

## Review Focus

- Google returns 200 with an unexpected unit (FAHRENHEIT / MILES_PER_HOUR) → reject, MET used (test in Task 1).
- 359,6° rounds to 360° → note says `kuzeyden, 0°` (Task 3).
- Imperial units on the page: wind box in mph as today, note stays m/s (owner text fixes m/s) (Task 3).
- Sıfırla of the Hava card clears the wind note (Task 4).
- Fallback when MET also fails → MET's failure surfaces (same message as today) (Task 2).

---

### Task 1: GoogleWeatherProvider
**Files:** Create `lib/tools/adapters/google_weather_provider.dart`; Modify `lib/tools/ports/weather_provider.dart` (add `enum WeatherSource { google, metNorway, other }`, field `source` default `other`); MET parse sets `source: WeatherSource.metNorway`. Test `test/google_weather_provider_test.dart`.
- [ ] Tests: fixture mapping (13,7 °C, 42 %, 1019,16 hPa, 8 km/h → 2,222… m/s, 335°), sourceName `Google`, source google; empty key → MockClient never called, `notConfigured`; non-200 → server; 429 → rateLimited; out-of-range/missing/unknown units → invalidResponse; header + query checked; key not in failure messages.
- [ ] Implement `GoogleWeatherProvider({http.Client? client, String apiKey = keyFromBuild, Clock clock, Duration timeout})`, static `parse(String body, {required DateTime fetchedAt})`.

### Task 2: FallbackWeatherProvider + wiring
**Files:** Create `lib/tools/adapters/fallback_weather_provider.dart`; Modify `lib/tools/tools_services.dart`. Test `test/fallback_weather_provider_test.dart`.
- [ ] Tests: primary ok → primary obs; primary throws any WeatherFailure / other error → secondary obs (source metNorway); both fail → secondary's failure.
- [ ] `FallbackWeatherProvider(WeatherProvider primary, WeatherProvider secondary)`; sourceName `Google ya da MET Norway (CC BY 4.0)`.

### Task 3: Wind note text
**Files:** Create `lib/features/ballistics/wind_source_note.dart`. Test `test/google_hava_notu_test.dart`.
- [ ] Tests: 8 directions × suffix, 0°/360°/359,6°, 22,4°/22,5° boundary, comma decimal, Google/MET/other prefix.
- [ ] `String windSourceNote(WeatherObservation o)`, `String turkishWindFrom(double deg)`.

### Task 4: Page wiring
**Files:** Modify `ballistics_screen.dart` (`_windNote` state, set in `_fillWeather`, cleared in `_resetWeather`), `hava_durumu_view.dart` (MenzilNotice info under the wind clock, key `environment-wind-source-note`). Widget test `test/google_hava_notu_widget_test.dart`; integration `integration_test/google_hava_notu_screens_test.dart`.
- [ ] Tests: both notes visible with Google fake and MET fake, left aligned, no overflow at 320 pt × 1,3; wind clock unchanged; Sıfırla clears note; solver output identical across sources.

### Task 5: Privacy texts, report, CI
- [ ] 02/03 docs, weather_screen source text via sourceName; `docs/reports/google_hava_verisi.md`; offline lint, python suite; CI dispatches.
