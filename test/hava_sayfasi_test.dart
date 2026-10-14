// Hava sayfası (owner, 2026-10-14 Istanbul; supersedes PR #302's labels).
// A: full-width weather button ("✓ Hava verisi alındı" / "⟳ Veriyi yenile"),
//    under it ONE always-visible row: date | Sıfırla; the Rüzgâr yönü dial
//    has a small title, stateOrange selection and "Saat 3 yönünde" | time.
// B: Pro → Rüzgâr düzeltmesi: En çok rüzgâr | Düzeltme al, auto-updated by
//    a weather fill that changes the wind, never over a typed value.
// C: Basınç Ölçer: one ⓘ in the title, "Basınç al" no longer writes İrtifa.
// D: İrtifa card: Haritadan (Google Elevation) | Telefondan (GPS, warmed up
//    silently when the page opens); the calculation uses Telefondan, else
//    Haritadan.
// Report: docs/reports/hava_sayfasi.md.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/environment_field_info.dart';
import 'package:sniper_turk/features/ballistics/fetch_date_text.dart';
import 'package:sniper_turk/features/ballistics/wind_clock_picker.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/tools/adapters/google_elevation_provider.dart';
import 'package:sniper_turk/tools/ports/elevation_provider.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/pro_sections.dart';
import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-hava',
  name: 'Hava',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _weatherBtn = Key('environment-fill-weather');
const _weatherDate = Key('environment-weather-date');
const _weatherReset = Key('environment-weather-reset');
const _pressureBtn = Key('environment-phone-pressure');
const _pressureDate = Key('environment-pressure-date');
const _pressureReset = Key('environment-pressure-reset');
const _mapBtn = Key('environment-map-altitude');
const _phoneBtn = Key('environment-phone-altitude');
const _altDate = Key('environment-altitude-date');
const _altReset = Key('environment-altitude-reset');
const _altStatus = Key('environment-altitude-status');
const _windMax = Key('pro-wind-max');
const _windMaxBtn = Key('pro-wind-max-fill');
const _windMaxDate = Key('pro-wind-max-date');

class _Rig {
  final TestClock clock = TestClock(DateTime(2026, 10, 14, 11, 20));
  late final TestWeather weather = TestWeather(
    observation(fetchedAt: clock.current.toUtc()),
  );
  final TestPressure pressure = TestPressure(const PressureRead(998.4));
  final TestLocation location = TestLocation(
    const LocationFix(39.9, 32.8, altitudeM: 900),
  );
  TestPhoneAltitude? phone;
  TestElevation? elevation;

  _Rig({this.phone, this.elevation});

  void advance(Duration d) => clock.current = clock.current.add(d);

  late final ToolsServices services = testServices(
    location: location,
    weather: weather,
    pressure: pressure,
    clock: clock,
    phoneAltitude: phone,
    elevation: elevation,
  );
}

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(_field(key)).controller!.text;

String _date(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

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

Widget _screen(BallisticsView view, {Key? key}) => Scaffold(
  body: BallisticsScreen(key: key, profile: _profile, view: view),
);

Future<void> _pump(
  WidgetTester tester,
  _Rig rig, {
  BallisticsView view = BallisticsView.environment,
  Key? key,
  Size size = const Size(430, 3000),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      _screen(view, key: key),
      services: rig.services,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

/// Same workspace, another view (as the shell does between tabs).
Future<void> _view(WidgetTester tester, _Rig rig, BallisticsView view) async {
  await tester.pumpWidget(host(_screen(view), services: rig.services));
  await tester.pumpAndSettle();
}

Future<void> _lifecycle(
  WidgetTester tester,
  List<AppLifecycleState> states,
) async {
  for (final s in states) {
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

  test('dates are numeric, 24 h, never month names', () {
    final t = DateTime(2026, 10, 4, 9, 5);
    expect(fetchDateText(t), '04.10.2026');
    expect(fetchDateTimeText(t.millisecondsSinceEpoch), '04.10.2026 09:05');
    expect(
      fetchDateTimeText(DateTime(2026, 10, 14, 23, 59).millisecondsSinceEpoch),
      '14.10.2026 23:59',
    );
  });

  group('A. Hava Durumu card', () {
    testWidgets('before a fetch: today\'s date | Sıfırla from the first '
        'frame; after: fetch date+time, no layout jump', (tester) async {
      final rig = _Rig();
      await _pump(tester, rig);
      expect(find.text('Konumdan canlı hava verisi al'), findsOneWidget);
      expect(_date(tester, _weatherDate), '14.10.2026');
      expect(find.byKey(_weatherReset), findsOneWidget);
      expect(find.textContaining('Alındı:'), findsNothing);
      expect(find.textContaining('Son alınma'), findsNothing);
      final dateTop = tester.getTopLeft(find.byKey(_weatherReset)).dy;
      // The button is full width; the reset button is half of it.
      final btn = tester.getSize(find.byKey(_weatherBtn)).width;
      final reset = tester.getSize(find.byKey(_weatherReset)).width;
      expect(reset, lessThan(btn * 0.6));

      rig.advance(const Duration(minutes: 16));
      await _tap(tester, _weatherBtn);
      expect(find.text('Hava verisi alındı'), findsOneWidget);
      expect(_button(tester, _weatherBtn).active, isTrue);
      expect(_button(tester, _weatherBtn).icon, Icons.check);
      expect(_button(tester, _weatherBtn).maxLabelLines, 1);
      expect(_date(tester, _weatherDate), '14.10.2026 11:36');
      expect(
        tester.getTopLeft(find.byKey(_weatherReset)).dy,
        moreOrLessEquals(dateTop, epsilon: 0.01),
      );
    });

    testWidgets('stale: "Veriyi yenile" on ONE line, the date stays', (
      tester,
    ) async {
      final rig = _Rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherBtn);
      rig.advance(const Duration(minutes: 31));
      await tester.pump(const Duration(minutes: 31));
      expect(find.text('Veriyi yenile'), findsOneWidget);
      expect(_button(tester, _weatherBtn).icon, Icons.refresh);
      expect(_button(tester, _weatherBtn).active, isFalse);
      expect(_button(tester, _weatherBtn).maxLabelLines, 1);
      expect(tester.widget<Text>(find.text('Veriyi yenile')).maxLines, 1);
      expect(_date(tester, _weatherDate), '14.10.2026 11:20');
    });

    testWidgets('a restored older fetch shows its own date and time', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        ShotSettingsStore.keyFor(_profile.id): jsonEncode(
          ShotSettings(
            weatherSaved: true,
            weatherSi: const {'temperature': 12, 'humidity': 70, 'wind': 2},
            weatherFromLocation: true,
            weatherFetchedAtMs: DateTime(
              2026,
              10,
              13,
              9,
              5,
            ).millisecondsSinceEpoch,
          ).toJson(),
        ),
      });
      await _pump(tester, _Rig());
      expect(_date(tester, _weatherDate), '13.10.2026 09:05');
      expect(find.text('Veriyi yenile'), findsOneWidget);
    });

    testWidgets('Rüzgâr yönü dial: title, stateOrange hour, "Saat 3 '
        'yönünde" | time, persisted', (tester) async {
      final rig = _Rig();
      await _pump(tester, rig);
      final title = find.byKey(const ValueKey('wind-clock-title'));
      expect(tester.widget<Text>(title).data, 'Rüzgâr yönü');
      final dial12 = find.byKey(WindClockPicker.hourKey(12));
      expect(
        tester.getBottomLeft(title).dy,
        lessThan(tester.getTopLeft(dial12).dy),
      );
      // Left-aligned with the dial area.
      final picker = find.byType(WindClockPicker);
      expect(
        tester.getTopLeft(title).dx,
        moreOrLessEquals(tester.getTopLeft(picker).dx, epsilon: 0.5),
      );
      const label = ValueKey('wind-clock-label');
      const when = ValueKey('wind-clock-date');
      expect(_date(tester, label), '');
      expect(_date(tester, when), '14.10.2026');

      rig.advance(const Duration(minutes: 35));
      await tester.ensureVisible(find.byKey(WindClockPicker.hourKey(3)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(WindClockPicker.hourKey(3)));
      await tester.pumpAndSettle();
      final selected = tester.widget<Material>(
        find.byKey(WindClockPicker.hourKey(3)),
      );
      expect(selected.color, MenzilColors.stateOrange);
      final digit = tester.widget<Text>(
        find.descendant(
          of: find.byKey(WindClockPicker.hourKey(3)),
          matching: find.text('3'),
        ),
      );
      expect(digit.style!.color, Colors.white);
      expect(
        tester.widget<Material>(find.byKey(WindClockPicker.hourKey(4))).color,
        isNot(MenzilColors.stateOrange),
      );
      expect(_date(tester, label), 'Saat 3 yönünde');
      expect(tester.widget<Text>(find.byKey(label)).maxLines, 1);
      expect(_date(tester, when), '14.10.2026 11:55');

      // A typed hour sets the time too.
      rig.advance(const Duration(minutes: 5));
      await _type(tester, BallisticsFieldKeys.windDirection, '9');
      expect(_date(tester, label), 'Saat 9 yönünde');
      expect(_date(tester, when), '14.10.2026 12:00');

      // Kept with the weather state.
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await _pump(tester, rig, key: UniqueKey());
      expect(_date(tester, label), 'Saat 9 yönünde');
      expect(_date(tester, when), '14.10.2026 12:00');
    });
  });

  group('B. Rüzgâr düzeltmesi', () {
    testWidgets('Düzeltme al → orange; a new weather wind updates it', (
      tester,
    ) async {
      final rig = _Rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherBtn); // 5,0 m/s
      await _view(tester, rig, BallisticsView.pro);
      await openProFor(tester, _windMax);
      expect(find.text('Düzeltme al'), findsOneWidget);
      expect(_date(tester, _windMaxDate), '14.10.2026');
      await _tap(tester, _windMaxBtn);
      expect(_text(tester, _windMax), '7.5');
      expect(find.text('Düzeltme alındı'), findsOneWidget);
      expect(_button(tester, _windMaxBtn).active, isTrue);
      expect(_button(tester, _windMaxBtn).icon, isNull);
      expect(_date(tester, _windMaxDate), '14.10.2026 11:20');
      expect(find.textContaining('Rüzgâr değişti'), findsNothing);
      expect(find.textContaining('Hava verisinden'), findsNothing);

      // New wind from the next weather fill: updated without a prompt.
      rig.advance(const Duration(minutes: 40));
      rig.weather.outcome = observation(
        fetchedAt: rig.clock.current.toUtc(),
        windSpeedMps: 8,
      );
      await _view(tester, rig, BallisticsView.environment);
      await _tap(tester, _weatherBtn);
      await _view(tester, rig, BallisticsView.pro);
      await openProFor(tester, _windMax);
      expect(_text(tester, _windMax), '12.0');
      expect(find.text('Düzeltme alındı'), findsOneWidget);
      expect(_date(tester, _windMaxDate), '14.10.2026 12:00');
    });

    testWidgets('a typed En çok rüzgâr is never overwritten', (tester) async {
      final rig = _Rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherBtn);
      await _view(tester, rig, BallisticsView.pro);
      await openProFor(tester, _windMax);
      await _tap(tester, _windMaxBtn);
      await _type(tester, _windMax, '9');
      expect(find.text('Düzeltme al'), findsOneWidget);
      expect(_date(tester, _windMaxDate), '14.10.2026');

      rig.weather.outcome = observation(
        fetchedAt: rig.clock.current.toUtc(),
        windSpeedMps: 8,
      );
      await _view(tester, rig, BallisticsView.environment);
      await _tap(tester, _weatherBtn);
      await _view(tester, rig, BallisticsView.pro);
      await openProFor(tester, _windMax);
      expect(_text(tester, _windMax), '9');
      expect(find.text('Düzeltme al'), findsOneWidget);
    });

    testWidgets('an empty box stays empty after a weather fill', (
      tester,
    ) async {
      final rig = _Rig();
      await _pump(tester, rig);
      await _tap(tester, _weatherBtn);
      await _view(tester, rig, BallisticsView.pro);
      await openProFor(tester, _windMax);
      expect(_text(tester, _windMax), '');
    });
  });

  group('C. Basınç Ölçer', () {
    testWidgets('one ⓘ in the title; labels; the button leaves İrtifa alone', (
      tester,
    ) async {
      final rig = _Rig(phone: TestPhoneAltitude(const LocationFailure('x')));
      await _pump(tester, rig);
      final info = find.byKey(const Key('environment-barometer-info'));
      expect(info, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(BallisticsFieldKeys.pressure),
          matching: find.byType(MenzilInfoButton),
        ),
        findsNothing,
      );
      await tester.tap(info);
      await tester.pumpAndSettle();
      expect(find.text(EnvironmentFieldInfo.barometerCard), findsOneWidget);
      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();

      expect(find.text('Basınç al'), findsOneWidget);
      expect(_date(tester, _pressureDate), '14.10.2026');
      await _type(tester, BallisticsFieldKeys.altitude, '500');
      await _type(tester, BallisticsFieldKeys.mapAltitude, '480');
      await _tap(tester, _pressureBtn);
      expect(_text(tester, BallisticsFieldKeys.pressure), '998.4');
      expect(find.text('Basınç alındı'), findsOneWidget);
      expect(_date(tester, _pressureDate), '14.10.2026 11:20');
      expect(_text(tester, BallisticsFieldKeys.altitude), '500');
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '480');

      rig.advance(const Duration(minutes: 31));
      await tester.pump(const Duration(minutes: 31));
      expect(find.text('Basıncı yenile'), findsOneWidget);
      expect(_button(tester, _pressureBtn).maxLabelLines, 1);

      // Sıfırla empties Basınç only.
      await _tap(tester, _pressureReset);
      expect(_text(tester, BallisticsFieldKeys.pressure), '');
      expect(_text(tester, BallisticsFieldKeys.altitude), '500');
      expect(_date(tester, _pressureDate), '14.10.2026');
    });
  });

  group('D. İrtifa card', () {
    testWidgets('page open: ONE silent request, nothing written or shown', (
      tester,
    ) async {
      final phone = TestPhoneAltitude(
        const LocationFix(39.9, 32.8, altitudeM: 126),
      );
      await _pump(tester, _Rig(phone: phone));
      expect(phone.permissionChecks, 1);
      expect(phone.requests, 1);
      expect(_text(tester, BallisticsFieldKeys.altitude), '');
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '');
      expect(find.text('Telefondan'), findsOneWidget);
      expect(find.text('Telefondan alındı'), findsNothing);
      expect(find.byKey(_altStatus), findsNothing);
      expect(_date(tester, _altDate), '14.10.2026');
      // The ⓘ is in the title only.
      expect(
        find.byKey(const Key('environment-altitude-info')),
        findsOneWidget,
      );
      for (final k in [
        BallisticsFieldKeys.altitude,
        BallisticsFieldKeys.mapAltitude,
      ]) {
        expect(
          find.descendant(
            of: find.byKey(k),
            matching: find.byType(MenzilInfoButton),
          ),
          findsNothing,
        );
      }
    });

    testWidgets('tap after the warm-up writes at once, orange, no icon', (
      tester,
    ) async {
      final phone = TestPhoneAltitude(
        const LocationFix(39.9, 32.8, altitudeM: 126.4),
      );
      final rig = _Rig(phone: phone);
      await _pump(tester, rig);
      rig.advance(const Duration(minutes: 3));
      await _tap(tester, _phoneBtn);
      expect(phone.requests, 2);
      expect(_text(tester, BallisticsFieldKeys.altitude), '126');
      expect(find.text('Telefondan alındı'), findsOneWidget);
      expect(_button(tester, _phoneBtn).active, isTrue);
      expect(_button(tester, _phoneBtn).icon, isNull);
      expect(_date(tester, _altDate), '14.10.2026 11:23');
      // No 30-minute rule for altitude.
      rig.advance(const Duration(hours: 2));
      await tester.pump(const Duration(hours: 2));
      expect(find.text('Telefondan alındı'), findsOneWidget);
      // Typing turns it back.
      await _type(tester, BallisticsFieldKeys.altitude, '130');
      expect(find.text('Telefondan'), findsOneWidget);
      expect(_button(tester, _phoneBtn).active, isFalse);
    });

    testWidgets('a tap while the warm-up is still running uses it (one '
        'request)', (tester) async {
      final phone = TestPhoneAltitude(const LocationFailure('x'))
        ..hold = Completer<LocationResult>();
      await _pump(tester, _Rig(phone: phone));
      expect(phone.requests, 1);
      await tester.ensureVisible(find.byKey(_phoneBtn));
      await tester.tap(find.byKey(_phoneBtn));
      await tester.pump();
      expect(phone.requests, 1);
      phone.hold!.complete(const LocationFix(39.9, 32.8, altitudeM: 88));
      await tester.pumpAndSettle();
      expect(_text(tester, BallisticsFieldKeys.altitude), '88');
      expect(phone.requests, 1);
    });

    testWidgets('no permission: no warm-up, no prompt; the button asks', (
      tester,
    ) async {
      final phone = TestPhoneAltitude(
        const LocationFix(39.9, 32.8, altitudeM: 126),
        granted: false,
      );
      await _pump(tester, _Rig(phone: phone));
      expect(phone.permissionChecks, 1);
      expect(phone.requests, 0);
      await _tap(tester, _phoneBtn);
      expect(phone.requests, 1);
      expect(_text(tester, BallisticsFieldKeys.altitude), '126');
    });

    testWidgets('closing the page drops a running warm-up (nothing left)', (
      tester,
    ) async {
      final phone = TestPhoneAltitude(const LocationFailure('x'))
        ..hold = Completer<LocationResult>();
      await _pump(tester, _Rig(phone: phone));
      await tester.pumpWidget(const SizedBox());
      phone.hold!.complete(const LocationFix(39.9, 32.8, altitudeM: 88));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('background drops the warm-up; the tap asks again', (
      tester,
    ) async {
      final phone = TestPhoneAltitude(const LocationFailure('x'))
        ..hold = Completer<LocationResult>();
      await _pump(tester, _Rig(phone: phone));
      await _lifecycle(tester, const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]);
      phone.hold!.complete(const LocationFix(39.9, 32.8, altitudeM: 88));
      await tester.pumpAndSettle();
      expect(_text(tester, BallisticsFieldKeys.altitude), '');
      await _lifecycle(tester, const [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
      phone
        ..hold = null
        ..result = const LocationFix(39.9, 32.8, altitudeM: 91);
      await _tap(tester, _phoneBtn);
      expect(phone.requests, 2);
      expect(_text(tester, BallisticsFieldKeys.altitude), '91');
    });

    testWidgets('no usable phone altitude: box empty and the right note', (
      tester,
    ) async {
      final phone = TestPhoneAltitude(const LocationFix(39.9, 32.8));
      final rig = _Rig(
        phone: phone,
        elevation: TestElevation(const ElevationRead(122)),
      );
      await _pump(tester, rig);
      await _tap(tester, _phoneBtn);
      expect(_text(tester, BallisticsFieldKeys.altitude), '');
      expect(
        tester.widget<MenzilNotice>(find.byKey(_altStatus)).message,
        'İrtifa alınamadı, elle girin.',
      );
      await _tap(tester, _mapBtn);
      await _tap(tester, _phoneBtn);
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '122');
      expect(
        tester.widget<MenzilNotice>(find.byKey(_altStatus)).message,
        'Telefon irtifası alınamadı; hesapta haritadan gelen irtifa '
        'kullanılıyor.',
      );
    });

    testWidgets('Haritadan: the phone position goes to the map service', (
      tester,
    ) async {
      final elevation = TestElevation(const ElevationRead(121.6));
      final rig = _Rig(elevation: elevation);
      await _pump(tester, rig);
      expect(find.text('Haritadan'), findsOneWidget);
      expect(_button(tester, _mapBtn).icon, Icons.terrain);
      expect(_button(tester, _phoneBtn).icon, Icons.my_location);
      expect(elevation.requests, isEmpty);
      await _tap(tester, _mapBtn);
      expect(elevation.requests, [(39.9, 32.8)]);
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '122');
      expect(find.text('Haritadan alındı'), findsOneWidget);
      expect(_button(tester, _mapBtn).icon, isNull);
      expect(_button(tester, _mapBtn).active, isTrue);
      expect(_date(tester, _altDate), '14.10.2026 11:20');

      // Offline next time: box empty, short note.
      elevation.result = const ElevationUnavailable(ElevationFailure.offline);
      await _tap(tester, _mapBtn);
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '');
      expect(
        find.text('İnternet yok; harita irtifası alınamadı.'),
        findsOneWidget,
      );
    });

    testWidgets('Sıfırla clears both boxes; the date is the latest fetch', (
      tester,
    ) async {
      final phone = TestPhoneAltitude(
        const LocationFix(39.9, 32.8, altitudeM: 126),
      );
      final rig = _Rig(
        phone: phone,
        elevation: TestElevation(const ElevationRead(122)),
      );
      await _pump(tester, rig);
      await _tap(tester, _mapBtn);
      rig.advance(const Duration(minutes: 7));
      await _tap(tester, _phoneBtn);
      expect(_date(tester, _altDate), '14.10.2026 11:27');
      await _tap(tester, _altReset);
      expect(_text(tester, BallisticsFieldKeys.altitude), '');
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '');
      expect(find.text('Haritadan'), findsOneWidget);
      expect(find.text('Telefondan'), findsOneWidget);
      expect(_date(tester, _altDate), '14.10.2026');
    });

    testWidgets('both altitudes and times are kept; restart reopens orange', (
      tester,
    ) async {
      final rig = _Rig(
        phone: TestPhoneAltitude(const LocationFix(39.9, 32.8, altitudeM: 126)),
        elevation: TestElevation(const ElevationRead(122)),
      );
      await _pump(tester, rig);
      await _tap(tester, _mapBtn);
      await _tap(tester, _phoneBtn);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      final raw = (await SharedPreferences.getInstance()).getString(
        ShotSettingsStore.keyFor(_profile.id),
      );
      final saved = ShotSettings.fromJson(jsonDecode(raw!));
      expect(saved.weatherSi['altitude'], 126);
      expect(saved.weatherSi['mapAltitude'], 122);
      expect(saved.altitudePhoneAtMs, rig.clock.current.millisecondsSinceEpoch);
      expect(saved.altitudeMapAtMs, rig.clock.current.millisecondsSinceEpoch);

      await _pump(tester, rig, key: UniqueKey());
      expect(_text(tester, BallisticsFieldKeys.altitude), '126');
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '122');
      expect(find.text('Telefondan alındı'), findsOneWidget);
      expect(find.text('Haritadan alındı'), findsOneWidget);
    });

    testWidgets('an older single İrtifa migrates to Telefondan irtifa', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        ShotSettingsStore.keyFor(_profile.id): jsonEncode({
          'weather': {'altitude': 900, 'pressure': 912.4},
          'pressurePhone': true,
        }),
      });
      await _pump(tester, _Rig());
      expect(_text(tester, BallisticsFieldKeys.altitude), '900');
      expect(_text(tester, BallisticsFieldKeys.mapAltitude), '');
      // No fetch time: a plain value, the button is not orange.
      expect(find.text('Telefondan'), findsOneWidget);
    });

    testWidgets('pressure check uses Telefondan, else Haritadan', (
      tester,
    ) async {
      await _pump(tester, _Rig());
      const warning = Key('environment-pressure-warning');
      await _type(tester, BallisticsFieldKeys.pressure, '1013');
      expect(find.byKey(warning), findsNothing);
      await _type(tester, BallisticsFieldKeys.mapAltitude, '1000');
      expect(find.byKey(warning), findsOneWidget);
      expect(find.textContaining('1000 m irtifada'), findsOneWidget);
      // The phone value wins.
      await _type(tester, BallisticsFieldKeys.altitude, '0');
      expect(find.byKey(warning), findsNothing);
    });
  });

  group('D. calculation: F1 pressure from the effective İrtifa', () {
    Future<double> density(
      WidgetTester tester, {
      required String phone,
      required String map,
    }) async {
      tester.view.physicalSize = const Size(430, 3000) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        host(
          const Scaffold(body: BallisticsScreen(profile: _profile)),
          services: _Rig().services,
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(_field(BallisticsFieldKeys.temperature), '15');
      await tester.enterText(_field(BallisticsFieldKeys.humidity), '0');
      await tester.enterText(_field(BallisticsFieldKeys.pressure), '');
      await tester.enterText(_field(BallisticsFieldKeys.altitude), phone);
      await tester.enterText(_field(BallisticsFieldKeys.mapAltitude), map);
      await tester.ensureVisible(find.text('DOPE oluştur'));
      await tester.tap(find.text('DOPE oluştur'));
      await tester.pumpAndSettle();
      final text = tester
          .widget<Text>(find.textContaining('Hava yoğunluğu:'))
          .data!;
      final m = RegExp(r'Hava yoğunluğu: ([\d,]+)').firstMatch(text)!;
      return double.parse(m.group(1)!.replaceAll(',', '.'));
    }

    testWidgets('map only is used; the phone value wins over it', (
      tester,
    ) async {
      // ISA: 1062,2 hPa at -400 m → 1,2842 kg/m³ dry at 15 °C.
      expect(
        await density(tester, phone: '', map: '-400'),
        closeTo(1.2842, 0.001),
      );
      expect(
        await density(tester, phone: '-400', map: ''),
        closeTo(1.2842, 0.001),
      );
      expect(
        await density(tester, phone: '0', map: '-400'),
        closeTo(1.2250, 0.001),
      );
      expect(await density(tester, phone: '', map: ''), closeTo(1.2250, 0.001));
    });
  });

  group('E. layout', () {
    testWidgets('320 pt, text scale 1.3: no overflow, one-line dates', (
      tester,
    ) async {
      final rig = _Rig(
        phone: TestPhoneAltitude(const LocationFix(39.9, 32.8, altitudeM: 126)),
        elevation: TestElevation(const ElevationRead(122)),
      );
      await _pump(tester, rig, size: const Size(320, 3000), textScale: 1.3);
      expect(tester.takeException(), isNull);
      for (final k in [_weatherBtn, _pressureBtn, _mapBtn, _phoneBtn]) {
        await _tap(tester, k);
        expect(tester.takeException(), isNull, reason: '$k');
      }
      await tester.tap(find.byKey(WindClockPicker.hourKey(3)));
      await tester.pumpAndSettle();
      for (final k in [_weatherDate, _pressureDate, _altDate]) {
        final t = tester.widget<Text>(find.byKey(k));
        expect(t.maxLines, 1, reason: '$k');
        expect(t.softWrap, isFalse, reason: '$k');
        expect(t.data, '14.10.2026 11:20');
      }
      // Two items per row: box | button side by side.
      for (final (box, btn) in [
        (BallisticsFieldKeys.pressure, _pressureBtn),
        (BallisticsFieldKeys.mapAltitude, _mapBtn),
        (BallisticsFieldKeys.altitude, _phoneBtn),
      ]) {
        expect(
          tester.getTopLeft(find.byKey(btn)).dx,
          greaterThan(tester.getTopRight(_field(box)).dx),
        );
      }
      for (final t in [
        'Hava verisi alındı',
        'Basınç alındı',
        'Haritadan alındı',
        'Telefondan alındı',
      ]) {
        expect(tester.widget<Text>(find.text(t)).maxLines, 1, reason: t);
      }
      rig.advance(const Duration(minutes: 31));
      await tester.pump(const Duration(minutes: 31));
      expect(find.text('Veriyi yenile'), findsOneWidget);
      expect(find.text('Basıncı yenile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Google Elevation adapter (fake HTTP)', () {
    test('sends the key and the iOS bundle header; reads the metres', () async {
      final seen = <http.Request>[];
      final client = MockClient((req) async {
        seen.add(req);
        return http.Response(
          jsonEncode({
            'status': 'OK',
            'results': [
              {'elevation': 126.37},
            ],
          }),
          200,
        );
      });
      final p = GoogleElevationProvider(client: client, apiKey: 'test-key');
      final r = await p.elevation(39.92077, 32.85411);
      expect(r, isA<ElevationRead>());
      expect((r as ElevationRead).meters, closeTo(126.37, 1e-9));
      expect(seen, hasLength(1));
      final u = seen.single.url;
      expect(u.host, 'maps.googleapis.com');
      expect(u.path, '/maps/api/elevation/json');
      expect(u.queryParameters['locations'], '39.92077,32.85411');
      expect(u.queryParameters['key'], 'test-key');
      expect(
        seen.single.headers['X-Ios-Bundle-Identifier'],
        'com.sniperturk.sniperTurk',
      );
    });

    test('no key: nothing is sent', () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        return http.Response('{}', 200);
      });
      final r = await GoogleElevationProvider(
        client: client,
        apiKey: '',
      ).elevation(39.9, 32.8);
      expect(calls, 0);
      expect((r as ElevationUnavailable).reason, ElevationFailure.noKey);
    });

    test('transient errors retry after 2 s and 5 s, then give up', () async {
      var calls = 0;
      final waits = <Duration>[];
      final client = MockClient((req) async {
        calls++;
        return http.Response('{"status":"UNKNOWN_ERROR"}', 200);
      });
      final r = await GoogleElevationProvider(
        client: client,
        apiKey: 'k',
        delay: (d) async => waits.add(d),
      ).elevation(39.9, 32.8);
      expect(calls, 3);
      expect(waits, const [Duration(seconds: 2), Duration(seconds: 5)]);
      expect((r as ElevationUnavailable).reason, ElevationFailure.error);
    });

    test('a 503 then OK: one retry, the value', () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        if (calls == 1) return http.Response('busy', 503);
        return http.Response(
          '{"status":"OK","results":[{"elevation":-12.5}]}',
          200,
        );
      });
      final r = await GoogleElevationProvider(
        client: client,
        apiKey: 'k',
        delay: (_) async {},
      ).elevation(39.9, 32.8);
      expect(calls, 2);
      expect((r as ElevationRead).meters, -12.5);
    });

    test('REQUEST_DENIED / 403 / offline are not retried', () async {
      for (final response in [
        http.Response('{"status":"REQUEST_DENIED"}', 200),
        http.Response('forbidden', 403),
      ]) {
        var calls = 0;
        final r = await GoogleElevationProvider(
          client: MockClient((_) async {
            calls++;
            return response;
          }),
          apiKey: 'k',
          delay: (_) async => fail('no retry'),
        ).elevation(39.9, 32.8);
        expect(calls, 1);
        expect((r as ElevationUnavailable).reason, ElevationFailure.error);
      }
      var calls = 0;
      final offline = await GoogleElevationProvider(
        client: MockClient((_) async {
          calls++;
          throw http.ClientException('offline');
        }),
        apiKey: 'k',
        delay: (_) async => fail('no retry'),
      ).elevation(39.9, 32.8);
      expect(calls, 1);
      expect(
        (offline as ElevationUnavailable).reason,
        ElevationFailure.offline,
      );
    });

    test('unreadable or impossible values are errors', () {
      for (final body in [
        'x',
        '{"status":"OK","results":[]}',
        '{"status":"OK","results":[{"elevation":"9"}]}',
        '{"status":"OK","results":[{"elevation":12000}]}',
      ]) {
        final (r, retry) = GoogleElevationProvider.parse(body);
        expect(r, isA<ElevationUnavailable>(), reason: body);
        expect(retry, isFalse, reason: body);
      }
    });
  });
}
