// Tek irtifa (owner, 2026-10-16 07:08–07:34 Istanbul): Hava Durumu → İrtifa
// card is ONE box "İrtifa" | ONE button "İrtifa al". The button asks the map
// (Google elevation) first; when that fails (no internet, no key, error) the
// phone GPS; neither → "İrtifa alınamadı, elle girin." and the box stays.
// "İrtifa alındı" uses the dark-blue done style, survives a reopen and is
// cleared by typing or Sıfırla. "-0" is never shown. Older saves with
// separate map/phone values load as the map value, else the phone value.
// Report: docs/reports/tek_irtifa.md.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/environment_field_info.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/tools/ports/elevation_provider.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-tek-irtifa',
  name: 'Tek irtifa',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _box = BallisticsFieldKeys.altitude;
const _btn = Key('environment-altitude-fetch');
const _reset = Key('environment-altitude-reset');
const _status = Key('environment-altitude-status');
const _info = Key('environment-altitude-info');

const _ownerInfo =
    'İrtifa; Atış yerinizin deniz seviyesinden yüksekliğidir. "İrtifa al" '
    'yüksekliği haritadan alır; internet yoksa telefonun GPS\'inden alır. '
    'Elle de girebilirsiniz. Örnek: 100 m.';

// Independent references (dry air, 15 °C; ISA from its base constants, as
// in test/audit_2026_10_14b/atmosphere_altitude_audit_test.dart).
const _rho0 = 1.2250; // 0 m, 1013,25 hPa
const _rho1500 = 1.0223; // 1500 m, 845,56 hPa
const _rho900hPa = 1.0881; // typed 900 hPa
const _rhoTol = 0.0008;

class _ThrowingElevation implements ElevationProvider {
  int requests = 0;
  @override
  Future<ElevationResult> elevation(double latitude, double longitude) {
    requests++;
    throw StateError('service down');
  }
}

class _Rig {
  final TestClock clock = TestClock(DateTime(2026, 10, 16, 7, 40));
  final TestLocation location;
  final TestPhoneAltitude? phone;
  final ElevationProvider? elevation;

  _Rig({this.phone, this.elevation, LocationResult? location})
    : location = TestLocation(location ?? const LocationFix(39.9, 32.8));

  late final ToolsServices services = testServices(
    location: location,
    clock: clock,
    phoneAltitude: phone,
    elevation: elevation,
  );
}

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(_field(key)).controller!.text;

MenzilSecondaryButton _button(WidgetTester tester) =>
    tester.widget<MenzilSecondaryButton>(find.byKey(_btn));

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

Future<void> _pump(
  WidgetTester tester,
  _Rig rig, {
  BallisticsView view = BallisticsView.environment,
  Size size = const Size(430, 3000),
  double textScale = 1.0,
  Key? key,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      Scaffold(
        body: BallisticsScreen(key: key, profile: _profile, view: view),
      ),
      services: rig.services,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

void _seed(Map<String, dynamic> json) {
  SharedPreferences.setMockInitialValues({
    ShotSettingsStore.keyFor(_profile.id): jsonEncode(json),
  });
}

Future<ShotSettings> _saved(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 1));
  final raw = (await SharedPreferences.getInstance()).getString(
    ShotSettingsStore.keyFor(_profile.id),
  );
  return ShotSettings.fromJson(jsonDecode(raw!));
}

double _density(WidgetTester tester) {
  final text = tester
      .widget<Text>(find.textContaining('Hava yoğunluğu:'))
      .data!;
  final m = RegExp(r'Hava yoğunluğu: ([\d,]+)').firstMatch(text)!;
  return double.parse(m.group(1)!.replaceAll(',', '.'));
}

Future<void> _dope(WidgetTester tester) async {
  await tester.ensureVisible(find.text('DOPE oluştur'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('DOPE oluştur'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('one row', () {
    testWidgets('one box "İrtifa" | one button "İrtifa al"; old rows gone', (
      tester,
    ) async {
      await _pump(tester, _Rig());
      expect(
        find.descendant(of: find.byKey(_box), matching: find.text('İrtifa')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _field(_box), matching: find.text('m')),
        findsOneWidget,
      );
      expect(find.text('İrtifa al'), findsOneWidget);
      expect(find.text('Haritadan irtifa'), findsNothing);
      expect(find.text('Telefondan irtifa'), findsNothing);
      expect(find.byKey(const Key('environment-map-altitude')), findsNothing);
      expect(find.byKey(const Key('environment-phone-altitude')), findsNothing);
      expect(find.byKey(const ValueKey('ballistics-map-altitude')), findsNothing);
      // Box | button side by side.
      expect(
        tester.getTopLeft(find.byKey(_btn)).dx,
        greaterThan(tester.getTopRight(_field(_box)).dx),
      );
      // Sıfırla and the date line stay.
      expect(find.byKey(_reset), findsOneWidget);
      expect(
        find.byKey(const Key('environment-altitude-date')),
        findsOneWidget,
      );
    });
  });

  group('"İrtifa al"', () {
    testWidgets('map OK → box = map value, "İrtifa alındı" dark blue', (
      tester,
    ) async {
      final phone = TestPhoneAltitude(
        const LocationFix(39.9, 32.8, altitudeM: 77),
      );
      final elevation = TestElevation(const ElevationRead(121.6));
      await _pump(tester, _Rig(phone: phone, elevation: elevation));
      final warmUps = phone.requests;
      await _tap(tester, _btn);
      expect(elevation.requests, [(39.9, 32.8)]);
      expect(_text(tester, _box), '122');
      // The map answered: no phone request beyond the page-open warm-up.
      expect(phone.requests, warmUps);
      expect(find.text('İrtifa alındı'), findsOneWidget);
      expect(_button(tester).active, isTrue);
      expect(find.byKey(_status), findsNothing);
      // The done style: #1F5F7A fill, #2E7FA0 border, white text.
      expect(MenzilDoneColors.fill, const Color(0xFF1F5F7A));
      expect(MenzilDoneColors.border, const Color(0xFF2E7FA0));
      expect(MenzilDoneColors.text, Colors.white);
      final style = tester
          .widget<OutlinedButton>(
            find.descendant(
              of: find.byKey(_btn),
              matching: find.byType(OutlinedButton),
            ),
          )
          .style!;
      expect(style.backgroundColor!.resolve({}), MenzilDoneColors.fill);
      expect(style.side!.resolve({})!.color, MenzilDoneColors.border);
      expect(style.foregroundColor!.resolve({}), MenzilDoneColors.text);
    });

    for (final (name, provider) in <(String, ElevationProvider? Function())>[
      (
        'no internet',
        () => TestElevation(const ElevationUnavailable(ElevationFailure.offline)),
      ),
      (
        'no key',
        () => TestElevation(const ElevationUnavailable(ElevationFailure.noKey)),
      ),
      (
        'service error',
        () => TestElevation(const ElevationUnavailable(ElevationFailure.error)),
      ),
      ('service throws', _ThrowingElevation.new),
      ('no map service in the build', () => null),
    ]) {
      testWidgets('map fails ($name) + phone OK → phone value', (
        tester,
      ) async {
        final phone = TestPhoneAltitude(
          const LocationFix(39.9, 32.8, altitudeM: 88.4),
        );
        await _pump(tester, _Rig(phone: phone, elevation: provider()));
        await _tap(tester, _btn);
        expect(_text(tester, _box), '88');
        expect(find.text('İrtifa alındı'), findsOneWidget);
        expect(find.byKey(_status), findsNothing);
        expect((await _saved(tester)).altitudeSource, 'phone');
      });
    }

    testWidgets('no position for the map → phone value', (tester) async {
      final elevation = TestElevation(const ElevationRead(500));
      final phone = TestPhoneAltitude(
        const LocationFix(39.9, 32.8, altitudeM: 64),
      );
      await _pump(
        tester,
        _Rig(
          phone: phone,
          elevation: elevation,
          location: const LocationFailure('x'),
        ),
      );
      await _tap(tester, _btn);
      expect(elevation.requests, isEmpty);
      expect(_text(tester, _box), '64');
    });

    testWidgets('both fail → the note, the box unchanged, no averaging', (
      tester,
    ) async {
      final phone = TestPhoneAltitude(
        // No usable vertical accuracy: the provider gives no altitude.
        const LocationFix(39.9, 32.8),
      );
      final elevation = TestElevation(
        const ElevationUnavailable(ElevationFailure.offline),
      );
      await _pump(tester, _Rig(phone: phone, elevation: elevation));
      await _type(tester, _box, '250');
      await _tap(tester, _btn);
      expect(_text(tester, _box), '250');
      expect(
        tester.widget<MenzilNotice>(find.byKey(_status)).message,
        'İrtifa alınamadı, elle girin.',
      );
      expect(find.text('İrtifa al'), findsOneWidget);
      expect(_button(tester).active, isFalse);

      // Empty box: stays empty.
      await _type(tester, _box, '');
      await _tap(tester, _btn);
      expect(_text(tester, _box), '');
      expect(find.text('İrtifa alınamadı, elle girin.'), findsOneWidget);
    });

    testWidgets('a failed retry keeps the earlier fetched value', (
      tester,
    ) async {
      final elevation = TestElevation(const ElevationRead(480));
      final phone = TestPhoneAltitude(const LocationFailure('x'));
      await _pump(tester, _Rig(phone: phone, elevation: elevation));
      await _tap(tester, _btn);
      expect(_text(tester, _box), '480');
      elevation.result = const ElevationUnavailable(ElevationFailure.offline);
      await _tap(tester, _btn);
      expect(_text(tester, _box), '480');
      expect(find.text('İrtifa alınamadı, elle girin.'), findsOneWidget);
    });
  });

  group('typed value, Sıfırla, reopen', () {
    testWidgets('a typed value is used as is and clears "alındı"', (
      tester,
    ) async {
      final rig = _Rig(elevation: TestElevation(const ElevationRead(122)));
      await _pump(tester, rig);
      await _tap(tester, _btn);
      expect(find.text('İrtifa alındı'), findsOneWidget);
      await _type(tester, _box, '1234.5');
      expect(_text(tester, _box), '1234.5');
      expect(find.text('İrtifa al'), findsOneWidget);
      expect(_button(tester).active, isFalse);
      final saved = await _saved(tester);
      expect(saved.weatherSi['mapAltitude'], 1234.5);
      expect(saved.altitudeMapAtMs, isNull);
      expect(saved.altitudeSource, 'typed');
    });

    testWidgets('Sıfırla clears the box and "alındı"', (tester) async {
      final rig = _Rig(elevation: TestElevation(const ElevationRead(122)));
      await _pump(tester, rig);
      await _tap(tester, _btn);
      await _tap(tester, _reset);
      expect(_text(tester, _box), '');
      expect(find.text('İrtifa al'), findsOneWidget);
      expect(_button(tester).active, isFalse);
      final saved = await _saved(tester);
      expect(saved.weatherSi.containsKey('mapAltitude'), isFalse);
      expect(saved.altitudeMapAtMs, isNull);
    });

    testWidgets('"İrtifa alındı" comes back when the page is reopened', (
      tester,
    ) async {
      final rig = _Rig(elevation: TestElevation(const ElevationRead(122)));
      await _pump(tester, rig);
      await _tap(tester, _btn);
      final saved = await _saved(tester);
      expect(saved.weatherSi['mapAltitude'], 122);
      expect(saved.altitudeSource, 'map');
      expect(saved.altitudeMapAtMs, rig.clock.current.millisecondsSinceEpoch);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, rig, key: UniqueKey());
      expect(_text(tester, _box), '122');
      expect(find.text('İrtifa alındı'), findsOneWidget);
      expect(_button(tester).active, isTrue);
    });
  });

  group('"-0"', () {
    testWidgets('map -0.3 → "0"', (tester) async {
      await _pump(
        tester,
        _Rig(elevation: TestElevation(const ElevationRead(-0.3))),
      );
      await _tap(tester, _btn);
      expect(_text(tester, _box), '0');
    });

    testWidgets('phone -0.4 → "0"; -0.6 stays "-1"', (tester) async {
      final phone = TestPhoneAltitude(
        const LocationFix(39.9, 32.8, altitudeM: -0.4),
      );
      await _pump(tester, _Rig(phone: phone));
      await _tap(tester, _btn);
      expect(_text(tester, _box), '0');
      phone.result = const LocationFix(39.9, 32.8, altitudeM: -0.6);
      await _tap(tester, _btn);
      expect(_text(tester, _box), '-1');
    });

    testWidgets('a saved negative zero loads as "0"', (tester) async {
      _seed({
        'weather': {'mapAltitude': -0.001},
        'altSource': 'map',
      });
      await _pump(tester, _Rig());
      expect(_text(tester, _box), '0');
    });
  });

  group('older saves load (never deleted)', () {
    testWidgets('map 5 + phone 2 → box 5; the phone value stays saved', (
      tester,
    ) async {
      final mapAt = DateTime(2026, 10, 15, 9).millisecondsSinceEpoch;
      final phoneAt = DateTime(2026, 10, 15, 10).millisecondsSinceEpoch;
      _seed({
        'weather': {'mapAltitude': 5, 'altitude': 2},
        'altMapAt': mapAt,
        'altPhoneAt': phoneAt,
      });
      await _pump(tester, _Rig());
      expect(_text(tester, _box), '5');
      expect(find.text('İrtifa alındı'), findsOneWidget);
      // A save from the new screen keeps the old phone value and time.
      await _type(tester, _box, '6');
      final saved = await _saved(tester);
      expect(saved.weatherSi['mapAltitude'], 6);
      expect(saved.weatherSi['altitude'], 2);
      expect(saved.altitudePhoneAtMs, phoneAt);
      // ... and the box still loads 6 (the new format ignores the old phone).
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, _Rig(), key: UniqueKey());
      expect(_text(tester, _box), '6');
    });

    testWidgets('only phone 2 → box 2 (with its "alındı")', (tester) async {
      _seed({
        'weather': {'altitude': 2},
        'altPhoneAt': DateTime(2026, 10, 15, 10).millisecondsSinceEpoch,
      });
      await _pump(tester, _Rig());
      expect(_text(tester, _box), '2');
      expect(find.text('İrtifa alındı'), findsOneWidget);
    });

    testWidgets('new format, emptied box: the old phone value is not shown', (
      tester,
    ) async {
      _seed({
        'weather': {'altitude': 2},
        'altSource': 'typed',
      });
      await _pump(tester, _Rig());
      expect(_text(tester, _box), '');
    });
  });

  group('calculation (only where İrtifa was used before)', () {
    Future<double> density(
      WidgetTester tester, {
      required String pressure,
      required String alt,
    }) async {
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, _Rig(), view: BallisticsView.all, key: UniqueKey());
      await _type(tester, BallisticsFieldKeys.temperature, '15');
      await _type(tester, BallisticsFieldKeys.humidity, '0');
      await _type(tester, BallisticsFieldKeys.pressure, pressure);
      await _type(tester, _box, alt);
      await _dope(tester);
      return _density(tester);
    }

    testWidgets('station pressure empty → the box value is used', (
      tester,
    ) async {
      expect(
        await density(tester, pressure: '', alt: '1500'),
        closeTo(_rho1500, _rhoTol),
      );
      expect(
        await density(tester, pressure: '', alt: ''),
        closeTo(_rho0, _rhoTol),
      );
    });

    testWidgets('station pressure filled → unchanged by İrtifa', (
      tester,
    ) async {
      expect(
        await density(tester, pressure: '900', alt: '1500'),
        closeTo(_rho900hPa, _rhoTol),
      );
      expect(
        await density(tester, pressure: '900', alt: ''),
        closeTo(_rho900hPa, _rhoTol),
      );
    });

    testWidgets('a fetched value is used too (old save with only phone)', (
      tester,
    ) async {
      _seed({
        'weather': {'temperature': 15, 'humidity': 0, 'altitude': 1500},
      });
      await _pump(tester, _Rig(), view: BallisticsView.all);
      expect(_text(tester, _box), '1500');
      await _dope(tester);
      expect(_density(tester), closeTo(_rho1500, _rhoTol));
    });
  });

  group('ⓘ', () {
    test('the İrtifa ⓘ is exactly the owner wording', () {
      expect(EnvironmentFieldInfo.altitudeCard, _ownerInfo);
    });

    testWidgets('the title ⓘ opens it', (tester) async {
      await _pump(tester, _Rig());
      await _tap(tester, _info);
      expect(find.text(_ownerInfo), findsOneWidget);
    });
  });

  group('layout', () {
    for (final width in [320.0, 390.0]) {
      testWidgets('$width pt, text scale 1.3: no overflow, one-line label', (
        tester,
      ) async {
        final rig = _Rig(elevation: TestElevation(const ElevationRead(1234)));
        await _pump(
          tester,
          rig,
          size: Size(width, 3000),
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        expect(tester.widget<Text>(find.text('İrtifa al')).maxLines, 1);
        await _tap(tester, _btn);
        expect(tester.takeException(), isNull);
        expect(tester.widget<Text>(find.text('İrtifa alındı')).maxLines, 1);
        expect(
          tester.getTopLeft(find.byKey(_btn)).dx,
          greaterThan(tester.getTopRight(_field(_box)).dx),
        );
        expect(
          tester.getTopRight(find.byKey(_btn)).dx,
          lessThanOrEqualTo(width),
        );
      });
    }
  });
}
