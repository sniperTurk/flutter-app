// Hava Durumu with the Google / MET Norway source (owner, 2026-10-17):
// the Hava note names the source, the Rüzgâr card shows the fetched wind as
// a note, the wind clock is never set from it, and the calculation does not
// depend on which service delivered the same values.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/wind_clock_picker.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/weather_provider.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _hava = Key('environment-weather-status');
const _ruzgar = Key('environment-wind-source-note');
const _fill = Key('environment-fill-weather');
const _reset = Key('environment-weather-reset');

WeatherObservation _obs(WeatherSource source) => WeatherObservation(
  temperatureC: 18.5,
  humidityPercent: 55,
  pressureHpa: 1012.3,
  pressureKind: PressureKind.seaLevel,
  windSpeedMps: 4.2,
  windFromDeg: 315,
  // 20:00 local time on the test machine.
  validAt: DateTime(2026, 10, 17, 20).toUtc(),
  fetchedAt: DateTime(2026, 10, 17, 20, 5).toUtc(),
  sourceName: source == WeatherSource.google
      ? 'Google'
      : 'MET Norway (CC BY 4.0)',
  source: source,
);

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(_field(key)).controller!.text;

String _message(WidgetTester tester, Key key) =>
    tester.widget<MenzilNotice>(find.byKey(key)).message;

Future<void> _pump(
  WidgetTester tester,
  WeatherSource source, {
  double width = 430,
  double textScale = 1.0,
  bool auto = true,
}) async {
  tester.view.physicalSize = Size(width, 3200) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      Scaffold(
        body: BallisticsScreen(
          profile: _profile,
          view: BallisticsView.environment,
          autoWeather: auto,
        ),
      ),
      textScale: textScale,
      services: testServices(
        location: TestLocation(const LocationFix(39.9, 32.8, altitudeM: 900)),
        weather: TestWeather(_obs(source)),
        clock: TestClock(DateTime(2026, 10, 17, 20, 5)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Google: both notes, exact owner texts', (tester) async {
    await _pump(tester, WeatherSource.google);
    expect(
      _message(tester, _hava),
      'Hava verisi konumdan dolduruldu (Google, 20:00). Basınç için '
      '"Basınç al", irtifa için İrtifa kartı. Rüzgâr yönünü siz seçin.',
    );
    expect(
      _message(tester, _ruzgar),
      'Google rüzgâr verisi (20:00): kuzeybatıdan, 315°, 4,2 m/s. '
      'Rüzgâr yönünü siz seçin.',
    );
    // Same box as the Hava note (info tone: blue left bar).
    expect(
      tester.widget<MenzilNotice>(find.byKey(_ruzgar)).tone,
      tester.widget<MenzilNotice>(find.byKey(_hava)).tone,
    );
    expect(
      tester.widget<MenzilNotice>(find.byKey(_ruzgar)).tone,
      MenzilNoticeTone.info,
    );
    // Rüzgâr hızı filled as today.
    expect(_text(tester, BallisticsFieldKeys.wind), '4.2');
  });

  testWidgets('MET Norway: Hava note unchanged, MET wind note', (tester) async {
    await _pump(tester, WeatherSource.metNorway);
    expect(
      _message(tester, _hava),
      'Hava verisi konumdan dolduruldu (MET Norway (CC BY 4.0), 20:00). '
      'Basınç için "Basınç al", irtifa için İrtifa kartı. Rüzgâr yönünü '
      'siz seçin.',
    );
    expect(
      _message(tester, _ruzgar),
      'MET Norway rüzgâr verisi (20:00): kuzeybatıdan, 315°, 4,2 m/s. '
      'Rüzgâr yönünü siz seçin.',
    );
  });

  testWidgets('no note before a fetch', (tester) async {
    await _pump(tester, WeatherSource.google, auto: false);
    expect(find.byKey(_ruzgar), findsNothing);
    expect(find.byKey(_hava), findsNothing);
  });

  testWidgets('wind clock is not set from the note', (tester) async {
    await _pump(tester, WeatherSource.google);
    expect(_text(tester, BallisticsFieldKeys.windDirection), '');
    expect(
      tester.widget<WindClockPicker>(find.byType(WindClockPicker)).hour,
      isNull,
    );
  });

  testWidgets('note sits at the bottom of the Rüzgâr card, left-aligned', (
    tester,
  ) async {
    await _pump(tester, WeatherSource.google);
    final note = tester.getRect(find.byKey(_ruzgar));
    final clock = tester.getRect(find.byType(WindClockPicker));
    final speed = tester.getRect(find.byKey(BallisticsFieldKeys.wind));
    expect(note.top, greaterThanOrEqualTo(clock.bottom));
    // Same left edge as the Rüzgâr hızı box (inside the card).
    expect(note.left, moreOrLessEquals(speed.left, epsilon: 0.5));
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byKey(_ruzgar),
        matching: find.textContaining('rüzgâr verisi'),
      ),
    );
    expect(text.textAlign, TextAlign.start);
  });

  testWidgets('Sıfırla clears the wind note with the other values', (
    tester,
  ) async {
    await _pump(tester, WeatherSource.google);
    expect(find.byKey(_ruzgar), findsOneWidget);
    await tester.ensureVisible(find.byKey(_reset));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_reset));
    await tester.pumpAndSettle();
    expect(find.byKey(_ruzgar), findsNothing);
    expect(_text(tester, BallisticsFieldKeys.wind), '');
    // A new fetch shows it again.
    await tester.ensureVisible(find.byKey(_fill));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_fill));
    await tester.pumpAndSettle();
    expect(find.byKey(_ruzgar), findsOneWidget);
  });

  for (final source in WeatherSource.values.take(2)) {
    testWidgets('no overflow at 320 pt, text ×1.3 (${source.name})', (
      tester,
    ) async {
      await _pump(tester, source, width: 320, textScale: 1.3);
      expect(tester.takeException(), isNull);
      for (final k in [_hava, _ruzgar]) {
        final r = tester.getRect(find.byKey(k));
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(320));
      }
    });
  }

  testWidgets('same values → same boxes and same Hava özeti, either source', (
    tester,
  ) async {
    Future<(List<String>, List<String>)> read(WeatherSource s) async {
      await _pump(tester, s);
      final boxes = [
        for (final k in [
          BallisticsFieldKeys.temperature,
          BallisticsFieldKeys.humidity,
          BallisticsFieldKeys.pressure,
          BallisticsFieldKeys.altitude,
          BallisticsFieldKeys.wind,
          BallisticsFieldKeys.windDirection,
        ])
          _text(tester, k),
      ];
      final card = find.byKey(const Key('environment-summary-card'));
      final summary = [
        for (final t in tester.widgetList<Text>(
          find.descendant(of: card, matching: find.byType(Text)),
        ))
          t.data ?? t.textSpan?.toPlainText() ?? '',
      ];
      return (boxes, summary);
    }

    final google = await read(WeatherSource.google);
    final met = await read(WeatherSource.metNorway);
    expect(google.$1, ['18.5', '55', '', '', '4.2', '']);
    expect(met.$1, google.$1);
    expect(google.$2, isNotEmpty);
    expect(met.$2, google.$2);
  });
}
