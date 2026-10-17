// Pre-TestFlight audit 2026-10-14b, area RUZ: Hava sayfası / rüzgâr /
// Google Elevation (PR #307, e3c2e26; reports docs/reports/hava_sayfasi.md
// and docs/reports/hava_verisi_tazelik.md).
//
// Chains checked (passing guards, no skip):
//  * En çok rüzgâr feeds ONLY the Hedef wind bracket row and the WEZ wind
//    uncertainty: the same inputs with and without it give the identical
//    windage (ScopeDialView.requiredRight); the bracket's low end is the
//    turret's own clicks, its high end the clicks of the turret at the
//    bracket wind; WEZ drops when the bracket widens.
//  * "Düzeltme al" = Rüzgâr hızı × 1.5 (hand calc in
//    tools/test_denetim_2026_10_14b_ruz.py); the button marker survives a
//    restart; a later weather fetch with a new wind empties the box and
//    its "Düzeltme alındı" (owner, 2026-10-15); a typed value survives
//    restart + fetch, a typed wind and Sıfırla.
//  * A weather fetch never writes Basınç, İrtifa (either box) or Rüzgâr
//    yönü, and keeps the Rüzgâr yönü time.
//  * Elevation adapter parsing edge cases (Dead Sea, bounds, statuses,
//    malformed bodies, NaN coordinates, timeout retry, blank key).
//  * İrtifa card: a Dead Sea map value is written as a negative number; a
//    rejected phone reading writes nothing into the calculation boxes.
//
// Findings (fixed 2026-10-15, docs/reports/ruz_en_cok_ruzgar.md; the
// owner's rule: a button-filled En çok rüzgâr is tied to the wind it was
// taken from and is emptied whenever Rüzgâr hızı changes):
//  * RUZ-1: a weather fetch that brings a calm wind (0 m/s) leaves the
//    button-filled En çok rüzgâr at the OLD × 1.5 value, still orange.
//  * RUZ-2: a typed Rüzgâr hızı (or Hava Durumu Sıfırla) leaves a
//    button-filled En çok rüzgâr from the old wind, still "Düzeltme alındı".
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/adapters/google_elevation_provider.dart';
import 'package:sniper_turk/tools/ports/elevation_provider.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import '../support/pro_sections.dart';
import '../support/tool_fakes.dart';

// A PCP slug with a manufacturer-style G1 BC so the drag solver (wind,
// bracket, WEZ) runs, as in test/shot_settings_test.dart.
const _ammo = <String, dynamic>{
  'id': 'c-ruz-x',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'Deneme',
  'model': '.25 slug',
  'caliberMm': 6.35,
  'grain': 34,
  'ammoType': 'slug',
  'bc': 0.08,
  'bcModel': 'G1',
};

const _profile = RifleProfile(
  id: 'p-ruz',
  name: 'Rüzgâr',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-ruz-x',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 60,
);

const _weatherBtn = Key('environment-fill-weather');
const _weatherReset = Key('environment-weather-reset');
const _altBtn = Key('environment-altitude-fetch');
const _windMax = Key('pro-wind-max');
const _windMaxBtn = Key('pro-wind-max-fill');
const _bracket = Key('shot-wind-bracket');

class _Rig {
  final TestClock clock = TestClock(DateTime(2026, 10, 14, 11, 20));
  late final TestWeather weather = TestWeather(
    observation(fetchedAt: clock.current.toUtc()),
  );
  final TestLocation location = TestLocation(
    const LocationFix(39.9, 32.8, altitudeM: 900),
  );
  TestPhoneAltitude? phone;
  TestElevation? elevation;

  _Rig({this.phone, this.elevation});

  void advance(Duration d) => clock.current = clock.current.add(d);

  void nextWind(double mps) => weather.outcome = observation(
    fetchedAt: clock.current.toUtc(),
    windSpeedMps: mps,
  );

  late final ToolsServices services = testServices(
    location: location,
    weather: weather,
    clock: clock,
    phoneAltitude: phone,
    elevation: elevation,
  );
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
  await openProFor(tester, key);
  await tester.ensureVisible(_field(key));
  await tester.pumpAndSettle();
  await tester.enterText(_field(key), v);
  await tester.pumpAndSettle();
}

/// Same workspace (same [key]) in another view, as the shell does between
/// tabs; a new key is a restart (state read back from SharedPreferences).
Future<void> _show(
  WidgetTester tester,
  _Rig rig,
  BallisticsView view, {
  Key? key,
}) async {
  tester.view.physicalSize = const Size(430, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      Scaffold(
        body: BallisticsScreen(key: key, profile: _profile, view: view),
      ),
      services: rig.services,
    ),
  );
  await tester.pumpAndSettle();
}

ScopeDialView _dial(WidgetTester tester) =>
    tester.widget<ScopeDialView>(find.byType(ScopeDialView));

/// (low, high) click counts of the bracket row.
(int, int) _bracketClicks(WidgetTester tester) {
  final text = tester.widget<Text>(find.byKey(_bracket)).data!;
  final m = RegExp(
    r'^Rüzgâr [\d,]+ m/s: (\d+) klik(?: sağ| sol)? · '
    r'[\d,]+ m/s: (\d+) klik(?: sağ| sol)?$',
  ).firstMatch(text);
  expect(m, isNotNull, reason: text);
  return (int.parse(m!.group(1)!), int.parse(m.group(2)!));
}

int _hitPct(WidgetTester tester) {
  final text = tester
      .widget<Text>(find.byKey(const Key('shot-hit-probability')))
      .data!;
  return int.parse(RegExp(r'%(\d+)').firstMatch(text)!.group(1)!);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('chain: En çok rüzgâr never moves the windage dial', () {
    testWidgets('same inputs with / without En çok rüzgâr: identical '
        'windage; bracket = turret clicks at wind and at wind × 1.5', (
      tester,
    ) async {
      final rig = _Rig();
      final ws = UniqueKey();
      await _show(tester, rig, BallisticsView.environment, key: ws);
      await _type(tester, BallisticsFieldKeys.wind, '4');
      await _type(tester, BallisticsFieldKeys.windDirection, '9');
      await _show(tester, rig, BallisticsView.pro, key: ws);
      await _type(tester, const Key('pro-shot-range'), '100');
      await _show(tester, rig, BallisticsView.shot, key: ws);
      final without = _dial(tester);
      expect(find.byKey(_bracket), findsNothing);
      expect(without.requiredRight.abs(), greaterThan(0));

      // Düzeltme al: 4 m/s × 1.5 = 6.0 (hand calc).
      await _show(tester, rig, BallisticsView.pro, key: ws);
      await openProFor(tester, _windMax);
      await _tap(tester, _windMaxBtn);
      expect(_text(tester, _windMax), '6.0');
      await _show(tester, rig, BallisticsView.shot, key: ws);
      final withMax = _dial(tester);
      // The scope correction comes from Rüzgâr hızı only.
      expect(withMax.requiredRight, closeTo(without.requiredRight, 1e-12));
      expect(withMax.requiredUp, closeTo(without.requiredUp!, 1e-12));
      final click = withMax.clickValue;
      final (lo, hi) = _bracketClicks(tester);
      // Low end = the turret's own windage clicks.
      expect(lo, (without.requiredRight.abs() / click).round());

      // High end = the turret's clicks when Rüzgâr hızı itself is 6 m/s.
      await _show(tester, rig, BallisticsView.environment, key: ws);
      await _type(tester, BallisticsFieldKeys.wind, '6');
      await _show(tester, rig, BallisticsView.shot, key: ws);
      final at6 = _dial(tester);
      // ±1 click: the bracket takes spin drift from the 4 m/s shot.
      expect(hi, closeTo((at6.requiredRight.abs() / click).round(), 1));
      // Crosswind drift is ~linear in crosswind speed (independent
      // reference: point-mass drift = w·(t − R/V0)), so 6/4 = 1.5 within
      // the click rounding and the small spin-drift offset.
      if (lo >= 8) {
        expect(hi / lo, inInclusiveRange(1.35, 1.65));
      }
    });

    testWidgets('WEZ: a wider bracket lowers the hit probability, the '
        'windage stays', (tester) async {
      final rig = _Rig();
      final ws = UniqueKey();
      await _show(tester, rig, BallisticsView.environment, key: ws);
      await _type(tester, BallisticsFieldKeys.wind, '4');
      await _type(tester, BallisticsFieldKeys.windDirection, '9');
      await _show(tester, rig, BallisticsView.pro, key: ws);
      await _type(tester, const Key('pro-shot-range'), '100');
      await _type(tester, const Key('pro-group'), '2');
      await _show(tester, rig, BallisticsView.shot, key: ws);
      final p0 = _hitPct(tester);
      final r0 = _dial(tester).requiredRight;

      await _show(tester, rig, BallisticsView.pro, key: ws);
      await _type(tester, _windMax, '12');
      await _show(tester, rig, BallisticsView.shot, key: ws);
      expect(_hitPct(tester), lessThan(p0));
      expect(_dial(tester).requiredRight, closeTo(r0, 1e-12));
    });
  });

  group('chain: Düzeltme al marker across restart', () {
    testWidgets('button value: restart keeps "Düzeltme alındı"; the next '
        'weather wind (8) empties it', (tester) async {
      final rig = _Rig();
      final a = UniqueKey();
      await _show(tester, rig, BallisticsView.environment, key: a);
      await _tap(tester, _weatherBtn); // 5.0 m/s
      await _show(tester, rig, BallisticsView.pro, key: a);
      await openProFor(tester, _windMax);
      await _tap(tester, _windMaxBtn);
      expect(_text(tester, _windMax), '7.5');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final b = UniqueKey();
      await _show(tester, rig, BallisticsView.pro, key: b);
      await openProFor(tester, _windMax);
      expect(_text(tester, _windMax), '7.5');
      expect(find.text('Düzeltme alındı'), findsOneWidget);

      rig.advance(const Duration(minutes: 40));
      rig.nextWind(8);
      await _show(tester, rig, BallisticsView.environment, key: b);
      await _tap(tester, _weatherBtn);
      await _show(tester, rig, BallisticsView.pro, key: b);
      await openProFor(tester, _windMax);
      // Owner, 2026-10-15: a new wind empties the button value; the user
      // presses "Düzeltme al" again.
      expect(_text(tester, _windMax), '');
      expect(find.text('Düzeltme al'), findsOneWidget);
    });

    testWidgets('button value: restart + a fetch with the same wind keeps '
        'it (restored "5" vs fetched "5.0" is no change)', (tester) async {
      final rig = _Rig();
      final a = UniqueKey();
      await _show(tester, rig, BallisticsView.environment, key: a);
      await _tap(tester, _weatherBtn); // 5.0 m/s
      await _show(tester, rig, BallisticsView.pro, key: a);
      await openProFor(tester, _windMax);
      await _tap(tester, _windMaxBtn);
      expect(_text(tester, _windMax), '7.5');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final b = UniqueKey();
      rig.advance(const Duration(minutes: 40));
      rig.nextWind(5);
      await _show(tester, rig, BallisticsView.environment, key: b);
      // The restored box shows two decimals at most: "5", not "5.0".
      expect(_text(tester, BallisticsFieldKeys.wind), '5');
      await _tap(tester, _weatherBtn);
      expect(_text(tester, BallisticsFieldKeys.wind), '5.0');
      await _show(tester, rig, BallisticsView.pro, key: b);
      await openProFor(tester, _windMax);
      expect(_text(tester, _windMax), '7.5');
      expect(find.text('Düzeltme alındı'), findsOneWidget);
    });

    testWidgets('typed value: restart + fetch never overwrite it', (
      tester,
    ) async {
      final rig = _Rig();
      final a = UniqueKey();
      await _show(tester, rig, BallisticsView.environment, key: a);
      await _tap(tester, _weatherBtn);
      await _show(tester, rig, BallisticsView.pro, key: a);
      await openProFor(tester, _windMax);
      await _tap(tester, _windMaxBtn);
      await _type(tester, _windMax, '9');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final b = UniqueKey();
      rig.nextWind(8);
      await _show(tester, rig, BallisticsView.environment, key: b);
      await _tap(tester, _weatherBtn);
      await _show(tester, rig, BallisticsView.pro, key: b);
      await openProFor(tester, _windMax);
      expect(_text(tester, _windMax), '9');
      expect(find.text('Düzeltme al'), findsOneWidget);
    });
  });

  group('RUZ-1: calm weather wind and a button-filled En çok rüzgâr', () {
    testWidgets(
      'a 0 m/s fetch does not leave the old × 1.5 value (7.5) orange',
      (tester) async {
        final rig = _Rig();
        final ws = UniqueKey();
        await _show(tester, rig, BallisticsView.environment, key: ws);
        await _tap(tester, _weatherBtn); // 5.0 m/s
        await _show(tester, rig, BallisticsView.pro, key: ws);
        await openProFor(tester, _windMax);
        await _tap(tester, _windMaxBtn);
        expect(_text(tester, _windMax), '7.5');

        rig.advance(const Duration(minutes: 40));
        rig.nextWind(0);
        await _show(tester, rig, BallisticsView.environment, key: ws);
        await _tap(tester, _weatherBtn);
        expect(_text(tester, BallisticsFieldKeys.wind), '0.0');
        await _show(tester, rig, BallisticsView.pro, key: ws);
        await openProFor(tester, _windMax);
        // Owner rule (2026-10-15): the wind changed → the button value is
        // emptied, never the old 7.5.
        expect(_text(tester, _windMax), '');
        expect(_button(tester, _windMaxBtn).active, isFalse);
        await _show(tester, rig, BallisticsView.shot, key: ws);
        expect(find.byKey(_bracket), findsNothing);
      },
    );
  });

  group('RUZ-2: Rüzgâr hızı changed without a fetch', () {
    Future<void> filled(WidgetTester tester, _Rig rig, Key ws) async {
      await _show(tester, rig, BallisticsView.environment, key: ws);
      await _tap(tester, _weatherBtn); // 5.0 m/s
      await _show(tester, rig, BallisticsView.pro, key: ws);
      await openProFor(tester, _windMax);
      await _tap(tester, _windMaxBtn);
      expect(_text(tester, _windMax), '7.5');
    }

    bool staleOrange(WidgetTester tester) =>
        _text(tester, _windMax) == '7.5' && _button(tester, _windMaxBtn).active;

    testWidgets(
      'typed wind 8: the box is not left at 7.5 as "Düzeltme alındı"',
      (tester) async {
        final rig = _Rig();
        final ws = UniqueKey();
        await filled(tester, rig, ws);
        await _show(tester, rig, BallisticsView.environment, key: ws);
        await _type(tester, BallisticsFieldKeys.wind, '8');
        await _show(tester, rig, BallisticsView.pro, key: ws);
        await openProFor(tester, _windMax);
        // Owner, 2026-10-15: the button value is emptied.
        expect(staleOrange(tester), isFalse);
        expect(_text(tester, _windMax), '');
        expect(find.text('Düzeltme al'), findsOneWidget);
      },
    );

    testWidgets('Hava Durumu Sıfırla (wind emptied): no stale orange 7.5', (
      tester,
    ) async {
      final rig = _Rig();
      final ws = UniqueKey();
      await filled(tester, rig, ws);
      await _show(tester, rig, BallisticsView.environment, key: ws);
      await _tap(tester, _weatherReset);
      expect(_text(tester, BallisticsFieldKeys.wind), '');
      await _show(tester, rig, BallisticsView.pro, key: ws);
      await openProFor(tester, _windMax);
      expect(staleOrange(tester), isFalse);
      expect(_text(tester, _windMax), '');
      expect(find.text('Düzeltme al'), findsOneWidget);
    });

    testWidgets(
      'a typed En çok rüzgâr survives a typed wind, a fetch, a calm fetch '
      'and Sıfırla',
      (tester) async {
        final rig = _Rig();
        final ws = UniqueKey();
        await filled(tester, rig, ws);
        await _type(tester, _windMax, '9');
        expect(find.text('Düzeltme al'), findsOneWidget);

        await _show(tester, rig, BallisticsView.environment, key: ws);
        await _type(tester, BallisticsFieldKeys.wind, '8');
        rig.advance(const Duration(minutes: 40));
        rig.nextWind(6);
        await _tap(tester, _weatherBtn);
        expect(_text(tester, BallisticsFieldKeys.wind), '6.0');
        rig.advance(const Duration(minutes: 40));
        rig.nextWind(0);
        await _tap(tester, _weatherBtn);
        expect(_text(tester, BallisticsFieldKeys.wind), '0.0');
        await _tap(tester, _weatherReset);
        expect(_text(tester, BallisticsFieldKeys.wind), '');

        await _show(tester, rig, BallisticsView.pro, key: ws);
        await openProFor(tester, _windMax);
        expect(_text(tester, _windMax), '9');
        expect(find.text('Düzeltme al'), findsOneWidget);
      },
    );
  });

  group(
    'chain: a weather fetch writes only Sıcaklık, Bağıl nem, Rüzgâr hızı',
    () {
      testWidgets('Basınç, the İrtifa box, Rüzgâr yönü and its time stay', (
        tester,
      ) async {
        // The location fix carries a GPS altitude (900 m): it must not leak.
        final rig = _Rig();
        await _show(tester, rig, BallisticsView.environment);
        await _type(tester, BallisticsFieldKeys.pressure, '900');
        await _type(tester, BallisticsFieldKeys.altitude, '500');
        await _type(tester, BallisticsFieldKeys.windDirection, '3');
        const when = ValueKey('wind-clock-date');
        final dirTime = tester.widget<Text>(find.byKey(when)).data;
        expect(dirTime, '14.10.2026 11:20');

        rig.advance(const Duration(minutes: 10));
        await _tap(tester, _weatherBtn);
        expect(_text(tester, BallisticsFieldKeys.wind), '5.0');
        expect(_text(tester, BallisticsFieldKeys.pressure), '900');
        expect(_text(tester, BallisticsFieldKeys.altitude), '500');
        expect(_text(tester, BallisticsFieldKeys.windDirection), '3');
        expect(tester.widget<Text>(find.byKey(when)).data, dirTime);
      });
    },
  );

  group('chain: İrtifa card writes', () {
    testWidgets('Dead Sea map elevation (−430.4 m) is written as −430', (
      tester,
    ) async {
      final rig = _Rig(elevation: TestElevation(const ElevationRead(-430.4)));
      await _show(tester, rig, BallisticsView.environment);
      await _tap(tester, _altBtn);
      expect(_text(tester, BallisticsFieldKeys.altitude), '-430');
      expect(find.text('İrtifa alındı'), findsOneWidget);
    });

    testWidgets('a rejected phone reading (no usable vertical accuracy) '
        'after a failed map writes nothing; the earlier value stays', (
      tester,
    ) async {
      final elevation = TestElevation(const ElevationRead(480));
      final rig = _Rig(
        phone: TestPhoneAltitude(const LocationFix(39.9, 32.8)),
        elevation: elevation,
      );
      await _show(tester, rig, BallisticsView.environment);
      await _tap(tester, _altBtn);
      expect(_text(tester, BallisticsFieldKeys.altitude), '480');
      elevation.result = const ElevationUnavailable(ElevationFailure.offline);
      await _tap(tester, _altBtn);
      expect(_text(tester, BallisticsFieldKeys.altitude), '480');
      expect(
        find.byKey(const Key('environment-altitude-status')),
        findsOneWidget,
      );
    });
  });

  group('Google Elevation parsing edge cases', () {
    (ElevationResult, bool) parse(String body) =>
        GoogleElevationProvider.parse(body);

    test('real terrain extremes and integer metres are read', () {
      for (final (body, m) in [
        ('{"status":"OK","results":[{"elevation":-430.5}]}', -430.5),
        ('{"status":"OK","results":[{"elevation":126}]}', 126.0),
        ('{"status":"OK","results":[{"elevation":-500}]}', -500.0),
        ('{"status":"OK","results":[{"elevation":8848.9}]}', 8848.9),
        ('{"status":"OK","results":[{"elevation":9000}]}', 9000.0),
      ]) {
        final (r, retry) = parse(body);
        expect(r, isA<ElevationRead>(), reason: body);
        expect((r as ElevationRead).meters, closeTo(m, 1e-9), reason: body);
        expect(retry, isFalse);
      }
    });

    test('out of range, wrong types and non-OK statuses are errors', () {
      for (final body in [
        '{"status":"OK","results":[{"elevation":-500.1}]}',
        '{"status":"OK","results":[{"elevation":9000.1}]}',
        '{"status":"OK","results":[{"elevation":null}]}',
        '{"status":"OK","results":[{}]}',
        '{"status":"OK","results":["x"]}',
        '{"status":"OK","results":{"elevation":1}}',
        '{"results":[{"elevation":10}]}',
        '{"status":"ZERO_RESULTS","results":[]}',
        '{"status":"INVALID_REQUEST","results":[]}',
        '{"status":"REQUEST_DENIED","results":[{"elevation":10}]}',
        '[{"elevation":10}]',
        '',
      ]) {
        final (r, retry) = parse(body);
        expect(r, isA<ElevationUnavailable>(), reason: body);
        expect(
          (r as ElevationUnavailable).reason,
          ElevationFailure.error,
          reason: body,
        );
        expect(retry, isFalse, reason: body);
      }
    });

    test('OVER_QUERY_LIMIT is transient', () {
      final (r, retry) = parse('{"status":"OVER_QUERY_LIMIT"}');
      expect(r, isA<ElevationUnavailable>());
      expect(retry, isTrue);
    });

    test('blank key or NaN coordinates: no request', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      });
      final blank = await GoogleElevationProvider(
        client: client,
        apiKey: '   ',
      ).elevation(39.9, 32.8);
      expect((blank as ElevationUnavailable).reason, ElevationFailure.noKey);
      final nan = await GoogleElevationProvider(
        client: client,
        apiKey: 'k',
      ).elevation(double.nan, 32.8);
      expect((nan as ElevationUnavailable).reason, ElevationFailure.error);
      expect(calls, 0);
    });

    test('a timeout is retried twice, then reported as offline', () async {
      var calls = 0;
      final waits = <Duration>[];
      final client = MockClient((_) {
        calls++;
        return Completer<http.Response>().future; // never answers
      });
      final r = await GoogleElevationProvider(
        client: client,
        apiKey: 'k',
        timeout: const Duration(milliseconds: 20),
        delay: (d) async => waits.add(d),
      ).elevation(39.9, 32.8);
      expect(calls, 3);
      expect(waits, GoogleElevationProvider.retryDelays);
      expect((r as ElevationUnavailable).reason, ElevationFailure.offline);
    });
  });
}
