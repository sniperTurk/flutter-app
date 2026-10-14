// Owner, TestFlight 2026-10-14 11:50: "Uygulamayı güncelledim, Hava
// Durumu'na girdim, 'Hava verisi alındı' turuncu ama tuşa bastım başka
// veriler geldi." A fetched value is orange ("…alındı") only for 30
// minutes, its date and time on the row below (2026-10-14: "14.10.2026
// 11:20"); after that the button is normal, "⟳ … yenile", and the
// values stay until refreshed or edited. Old saves without a time, and a
// fetch time in the future (clock set back), count as old.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';
import 'package:sniper_turk/tools/ports/weather_provider.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-fresh',
  name: 'Taze',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _weatherKey = Key('environment-fill-weather');
const _pressureKey = Key('environment-phone-pressure');
const _weatherDate = Key('environment-weather-date');
const _pressureDate = Key('environment-pressure-date');

/// The date row under a fetch button (owner, 2026-10-14).
String _date(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

/// 11:20 on the phone (local time, so the label reads 11:20 in any zone).
DateTime _at1120() => DateTime(2026, 10, 14, 11, 20);

class _Rig {
  final TestClock clock;
  final TestWeather weather;
  final TestPressure pressure;
  _Rig(this.clock, this.weather, this.pressure);

  void advance(Duration d) => clock.current = clock.current.add(d);
}

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(_field(key)).controller!.text;

MenzilSecondaryButton _button(WidgetTester tester, Key key) =>
    tester.widget<MenzilSecondaryButton>(find.byKey(key));

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, Key key, String v) async {
  await tester.ensureVisible(_field(key));
  await tester.pumpAndSettle();
  await tester.enterText(_field(key), v);
  await tester.pumpAndSettle();
}

/// The Hava Durumu page of [_profile] on [rig]'s fakes. A new [key] builds
/// a new workspace (= the app started again on the same storage).
Future<void> _pump(WidgetTester tester, _Rig rig, {Key? key}) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      Scaffold(
        body: BallisticsScreen(
          key: key,
          profile: _profile,
          view: BallisticsView.environment,
        ),
      ),
      services: testServices(
        location: TestLocation(const LocationFix(39.9, 32.8, altitudeM: 900)),
        weather: rig.weather,
        pressure: rig.pressure,
        clock: rig.clock,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

_Rig _rig([DateTime? now]) {
  final clock = TestClock(now ?? _at1120());
  return _Rig(
    clock,
    TestWeather(observation(fetchedAt: clock.current.toUtc())),
    TestPressure(const PressureRead(912.4)),
  );
}

/// Saved state as an older (or this) build wrote it.
void _saved({
  bool weather = false,
  bool pressure = false,
  int? weatherAtMs,
  int? pressureAtMs,
}) {
  SharedPreferences.setMockInitialValues({
    ShotSettingsStore.keyFor(_profile.id): jsonEncode(
      ShotSettings(
        weatherSaved: true,
        weatherSi: const {
          'temperature': 18.5,
          'humidity': 55,
          'wind': 5,
          'pressure': 912.4,
          'altitude': 900,
        },
        weatherFromLocation: weather,
        pressureFromPhone: pressure,
        weatherFetchedAtMs: weatherAtMs,
        pressureFetchedAtMs: pressureAtMs,
      ).toJson(),
    ),
  });
}

Future<void> _resumeApp(WidgetTester tester) async {
  // A legal background -> foreground sequence.
  for (final s in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(s.toString()),
      (_) {},
    );
  }
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fetch times round-trip; missing or damaged ones are none', () {
    const s = ShotSettings(
      weatherFromLocation: true,
      pressureFromPhone: true,
      weatherFetchedAtMs: 1760430000000,
      pressureFetchedAtMs: 1760430060000,
    );
    final back = ShotSettings.fromJson(jsonDecode(jsonEncode(s.toJson())));
    expect(back.weatherFetchedAtMs, 1760430000000);
    expect(back.pressureFetchedAtMs, 1760430060000);
    // An older save: no time at all.
    final old = ShotSettings.fromJson({'weatherGps': true});
    expect(old.weatherFromLocation, isTrue);
    expect(old.weatherFetchedAtMs, isNull);
    for (final bad in ['x', -5, 0, 1.5, double.nan]) {
      expect(
        ShotSettings.fromJson({'weatherGpsAt': bad}).weatherFetchedAtMs,
        isNull,
        reason: '$bad',
      );
    }
  });

  group('Hava verisi', () {
    testWidgets('11:20 orange; +29 min orange; +31 min eski, values kept; '
        'Yenile fetches again', (tester) async {
      final rig = _rig();
      await _pump(tester, rig);
      expect(find.text('Konumdan canlı hava verisi al'), findsOneWidget);

      await _tap(tester, _weatherKey);
      expect(find.text('Hava verisi alındı'), findsOneWidget);
      expect(_date(tester, _weatherDate), '14.10.2026 11:20');
      expect(_button(tester, _weatherKey).active, isTrue);
      expect(_button(tester, _weatherKey).icon, Icons.check);
      expect(_button(tester, _weatherKey).maxLabelLines, 1);
      expect(rig.weather.calls, 1);

      // +29 min, page open: still current.
      rig.advance(const Duration(minutes: 29));
      await tester.pump(const Duration(minutes: 29));
      expect(find.text('Hava verisi alındı'), findsOneWidget);
      expect(_date(tester, _weatherDate), '14.10.2026 11:20');
      expect(_button(tester, _weatherKey).active, isTrue);

      // +31 min: the page's own timer turns it old, without a tap.
      rig.advance(const Duration(minutes: 2));
      await tester.pump(const Duration(minutes: 2));
      expect(find.text('Veriyi yenile'), findsOneWidget);
      expect(find.textContaining('Hava verisi alındı'), findsNothing);
      expect(_button(tester, _weatherKey).active, isFalse);
      expect(_button(tester, _weatherKey).icon, Icons.refresh);
      // The boxes keep the fetched values.
      expect(_text(tester, BallisticsFieldKeys.temperature), '18.5');
      expect(_text(tester, BallisticsFieldKeys.humidity), '55');
      expect(_text(tester, BallisticsFieldKeys.wind), '5.0');
      expect(rig.weather.calls, 1);

      // Tapping fetches again: orange with the new time (11:51).
      await _tap(tester, _weatherKey);
      expect(rig.weather.calls, 2);
      expect(find.text('Hava verisi alındı'), findsOneWidget);
      expect(_date(tester, _weatherDate), '14.10.2026 11:51');
      expect(_button(tester, _weatherKey).active, isTrue);
    });

    testWidgets('exactly 30 min is still current', (tester) async {
      final rig = _rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherKey);
      rig.advance(const Duration(minutes: 30));
      // A resume rebuilds the page at exactly 30 min.
      await _resumeApp(tester);
      expect(find.text('Hava verisi alındı'), findsOneWidget);
      expect(_date(tester, _weatherDate), '14.10.2026 11:20');
      // One more second: old.
      rig.advance(const Duration(seconds: 1));
      await _resumeApp(tester);
      expect(find.text('Veriyi yenile'), findsOneWidget);
    });

    testWidgets('restart: the saved time comes back, old is old', (
      tester,
    ) async {
      final rig = _rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherKey);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      final raw = (await SharedPreferences.getInstance()).getString(
        ShotSettingsStore.keyFor(_profile.id),
      );
      expect(
        ShotSettings.fromJson(jsonDecode(raw!)).weatherFetchedAtMs,
        _at1120().millisecondsSinceEpoch,
      );

      // Started again 10 min later: still 11:20, orange.
      rig.advance(const Duration(minutes: 10));
      await _pump(tester, rig, key: UniqueKey());
      expect(find.text('Hava verisi alındı'), findsOneWidget);
      expect(_date(tester, _weatherDate), '14.10.2026 11:20');

      // Started again hours later: old, values kept.
      rig.advance(const Duration(hours: 3));
      await _pump(tester, rig, key: UniqueKey());
      expect(find.text('Veriyi yenile'), findsOneWidget);
      expect(_button(tester, _weatherKey).active, isFalse);
      expect(_text(tester, BallisticsFieldKeys.temperature), '18.5');
    });

    testWidgets('old save without a time opens as eski', (tester) async {
      _saved(weather: true);
      await _pump(tester, _rig());
      expect(find.text('Veriyi yenile'), findsOneWidget);
      expect(_button(tester, _weatherKey).active, isFalse);
      expect(_text(tester, BallisticsFieldKeys.temperature), '18.5');
    });

    testWidgets('saved 10 min ago opens orange with its time', (tester) async {
      _saved(
        weather: true,
        weatherAtMs: DateTime(2026, 10, 14, 11, 10).millisecondsSinceEpoch,
      );
      await _pump(tester, _rig());
      expect(find.text('Hava verisi alındı'), findsOneWidget);
      expect(_date(tester, _weatherDate), '14.10.2026 11:10');
      expect(_button(tester, _weatherKey).active, isTrue);
    });

    testWidgets('clock set back (fetch time in the future) → eski', (
      tester,
    ) async {
      _saved(
        weather: true,
        weatherAtMs: DateTime(2026, 10, 14, 12, 0).millisecondsSinceEpoch,
      );
      await _pump(tester, _rig());
      expect(find.text('Veriyi yenile'), findsOneWidget);
      expect(_button(tester, _weatherKey).active, isFalse);
    });

    testWidgets('clock set back while open → eski on resume', (tester) async {
      final rig = _rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherKey);
      rig.advance(const Duration(hours: -1));
      await _resumeApp(tester);
      expect(find.text('Veriyi yenile'), findsOneWidget);
    });

    testWidgets('a typed Sıcaklık is not orange (existing rule)', (
      tester,
    ) async {
      final rig = _rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherKey);
      await _type(tester, BallisticsFieldKeys.temperature, '20');
      expect(_button(tester, _weatherKey).active, isFalse);
      expect(find.textContaining('Hava verisi alındı'), findsNothing);
      expect(find.textContaining('Hava verisi eski'), findsNothing);
      expect(find.text('Konumdan canlı hava verisi al'), findsOneWidget);
    });

    testWidgets('resume after 31 min → eski without a tap', (tester) async {
      final rig = _rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherKey);
      // Time passes while the app is in the background (no timer ran).
      rig.advance(const Duration(minutes: 31));
      await tester.pump();
      expect(find.text('Hava verisi alındı'), findsOneWidget);
      expect(_date(tester, _weatherDate), '14.10.2026 11:20');
      await _resumeApp(tester);
      expect(find.text('Veriyi yenile'), findsOneWidget);
      expect(_text(tester, BallisticsFieldKeys.temperature), '18.5');
    });

    testWidgets('midnight: 23:50 stays current at 00:10, eski at 00:21', (
      tester,
    ) async {
      final rig = _rig(DateTime(2026, 10, 14, 23, 50));
      await _pump(tester, rig);
      await _tap(tester, _weatherKey);
      expect(find.text('Hava verisi alındı'), findsOneWidget);
      expect(_date(tester, _weatherDate), '14.10.2026 23:50');
      rig.advance(const Duration(minutes: 20));
      await tester.pump(const Duration(minutes: 20));
      expect(find.text('Hava verisi alındı'), findsOneWidget);
      expect(_date(tester, _weatherDate), '14.10.2026 23:50');
      rig.advance(const Duration(minutes: 11));
      await tester.pump(const Duration(minutes: 11));
      expect(find.text('Veriyi yenile'), findsOneWidget);
    });

    testWidgets('Sıfırla unchanged: empties and shows Veriler sıfırlandı', (
      tester,
    ) async {
      final rig = _rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherKey);
      rig.advance(const Duration(minutes: 31));
      await tester.pump(const Duration(minutes: 31));
      await _tap(tester, const Key('environment-weather-reset'));
      expect(_text(tester, BallisticsFieldKeys.temperature), '');
      expect(find.text('Veriler sıfırlandı'), findsOneWidget);
      expect(find.text('Tekrar canlı konum verisi al'), findsOneWidget);
    });

    testWidgets('a failed refetch keeps eski and the values', (tester) async {
      final rig = _rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherKey);
      rig.advance(const Duration(minutes: 31));
      await tester.pump(const Duration(minutes: 31));
      // Offline now.
      rig.weather.outcome = const WeatherFailure(
        WeatherFailureKind.offline,
        'x',
      );
      await _tap(tester, _weatherKey);
      expect(find.text('Veriyi yenile'), findsOneWidget);
      expect(_text(tester, BallisticsFieldKeys.temperature), '18.5');
    });

    testWidgets('the timer goes with the page (none left pending)', (
      tester,
    ) async {
      final rig = _rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherKey);
      await _tap(tester, _pressureKey);
      // Page closed with both 30-minute timers armed.
      await tester.pumpWidget(const SizedBox());
      rig.advance(const Duration(hours: 1));
      await tester.pump(const Duration(hours: 1));
      expect(tester.takeException(), isNull);
      // flutter_test also fails the test if a Timer is still pending here.
    });
  });

  group('Basınç', () {
    testWidgets('11:20 orange; +29 min orange; +31 min eski, values kept; '
        'Yenile reads again', (tester) async {
      final rig = _rig();
      await _pump(tester, rig);
      expect(find.text('Basınç al'), findsOneWidget);

      await _tap(tester, _pressureKey);
      expect(find.text('Basınç alındı'), findsOneWidget);
      expect(_date(tester, _pressureDate), '14.10.2026 11:20');
      expect(_button(tester, _pressureKey).active, isTrue);
      expect(_button(tester, _pressureKey).maxLabelLines, 1);
      expect(rig.pressure.reads, 1);

      rig.advance(const Duration(minutes: 29));
      await tester.pump(const Duration(minutes: 29));
      expect(find.text('Basınç alındı'), findsOneWidget);
      expect(_date(tester, _pressureDate), '14.10.2026 11:20');

      rig.advance(const Duration(minutes: 2));
      await tester.pump(const Duration(minutes: 2));
      expect(find.text('Basıncı yenile'), findsOneWidget);
      expect(_button(tester, _pressureKey).active, isFalse);
      expect(_button(tester, _pressureKey).icon, Icons.refresh);
      expect(_text(tester, BallisticsFieldKeys.pressure), '912.4');
      // The pressure button no longer writes İrtifa (owner, 2026-10-14).
      expect(_text(tester, BallisticsFieldKeys.altitude), '');

      await _tap(tester, _pressureKey);
      expect(rig.pressure.reads, 2);
      expect(find.text('Basınç alındı'), findsOneWidget);
      expect(_date(tester, _pressureDate), '14.10.2026 11:51');
      expect(_button(tester, _pressureKey).active, isTrue);
    });

    testWidgets('restart: saved time comes back, hours later eski', (
      tester,
    ) async {
      final rig = _rig();
      await _pump(tester, rig);
      await _tap(tester, _pressureKey);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      rig.advance(const Duration(minutes: 10));
      await _pump(tester, rig, key: UniqueKey());
      expect(find.text('Basınç alındı'), findsOneWidget);
      expect(_date(tester, _pressureDate), '14.10.2026 11:20');
      rig.advance(const Duration(hours: 3));
      await _pump(tester, rig, key: UniqueKey());
      expect(find.text('Basıncı yenile'), findsOneWidget);
      expect(_text(tester, BallisticsFieldKeys.pressure), '912.4');
    });

    testWidgets('old save without a time opens as eski', (tester) async {
      _saved(pressure: true);
      await _pump(tester, _rig());
      expect(find.text('Basıncı yenile'), findsOneWidget);
      expect(_button(tester, _pressureKey).active, isFalse);
      expect(_text(tester, BallisticsFieldKeys.pressure), '912.4');
    });

    testWidgets('clock set back (fetch time in the future) → eski', (
      tester,
    ) async {
      _saved(
        pressure: true,
        pressureAtMs: DateTime(2026, 10, 14, 12, 0).millisecondsSinceEpoch,
      );
      await _pump(tester, _rig());
      expect(find.text('Basıncı yenile'), findsOneWidget);
    });

    testWidgets('a typed Basınç is not orange (existing rule)', (tester) async {
      final rig = _rig();
      await _pump(tester, rig);
      await _tap(tester, _pressureKey);
      await _type(tester, BallisticsFieldKeys.pressure, '900');
      expect(_button(tester, _pressureKey).active, isFalse);
      expect(find.text('Basınç al'), findsOneWidget);
    });

    testWidgets('resume after 31 min → eski without a tap', (tester) async {
      final rig = _rig();
      await _pump(tester, rig);
      await _tap(tester, _pressureKey);
      rig.advance(const Duration(minutes: 31));
      await tester.pump();
      expect(find.text('Basınç alındı'), findsOneWidget);
      expect(_date(tester, _pressureDate), '14.10.2026 11:20');
      await _resumeApp(tester);
      expect(find.text('Basıncı yenile'), findsOneWidget);
    });

    testWidgets('each button has its own time', (tester) async {
      final rig = _rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherKey);
      rig.advance(const Duration(minutes: 20));
      await tester.pump(const Duration(minutes: 20));
      await _tap(tester, _pressureKey);
      expect(find.text('Basınç alındı'), findsOneWidget);
      expect(_date(tester, _pressureDate), '14.10.2026 11:40');
      // 11:51: weather old, pressure (11:40) still current.
      rig.advance(const Duration(minutes: 11));
      await tester.pump(const Duration(minutes: 11));
      expect(find.text('Veriyi yenile'), findsOneWidget);
      expect(find.text('Basınç alındı'), findsOneWidget);
      expect(_date(tester, _pressureDate), '14.10.2026 11:40');
      // 12:11: both old.
      rig.advance(const Duration(minutes: 20));
      await tester.pump(const Duration(minutes: 20));
      expect(find.text('Basıncı yenile'), findsOneWidget);
    });
  });

  testWidgets('narrow phone, text scale 1.3: done texts fit on one line', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 2600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final rig = _rig();
    await tester.pumpWidget(
      host(
        const Scaffold(
          body: BallisticsScreen(
            profile: _profile,
            view: BallisticsView.environment,
          ),
        ),
        services: testServices(
          location: TestLocation(const LocationFix(39.9, 32.8, altitudeM: 900)),
          weather: rig.weather,
          pressure: rig.pressure,
          clock: rig.clock,
        ),
        textScale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, _weatherKey);
    await _tap(tester, _pressureKey);
    expect(tester.takeException(), isNull);
    for (final t in ['Hava verisi alındı', 'Basınç alındı']) {
      expect(tester.widget<Text>(find.text(t)).maxLines, 1, reason: t);
    }
    rig.advance(const Duration(minutes: 31));
    await tester.pump(const Duration(minutes: 31));
    expect(tester.takeException(), isNull);
    expect(find.text('Veriyi yenile'), findsOneWidget);
    expect(find.text('Basıncı yenile'), findsOneWidget);
  });

  testWidgets('tabs (Hava Durumu → Hedef → back) keep the fetch time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final rig = _rig();
    final store = MemoryProfileStore();
    final active = MemoryActiveProfileStore();
    await store.save(_profile);
    active.value = _profile.id;
    await tester.pumpWidget(
      host(
        HomeScreen(profileStore: store, activeProfileStore: active),
        services: testServices(
          location: TestLocation(const LocationFix(39.9, 32.8, altitudeM: 900)),
          weather: rig.weather,
          pressure: rig.pressure,
          clock: rig.clock,
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> tab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(MenzilBottomNavigation),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    await tab('Hava Durumu');
    await _tap(tester, _weatherKey);
    expect(find.text('Hava verisi alındı'), findsOneWidget);
    expect(_date(tester, _weatherDate), '14.10.2026 11:20');
    await tab('Hedef');
    rig.advance(const Duration(minutes: 10));
    await tab('Hava Durumu');
    expect(find.text('Hava verisi alındı'), findsOneWidget);
    expect(_date(tester, _weatherDate), '14.10.2026 11:20');
    await tab('Hedef');
    rig.advance(const Duration(minutes: 25));
    await tab('Hava Durumu');
    expect(find.text('Veriyi yenile'), findsOneWidget);
  });
}
