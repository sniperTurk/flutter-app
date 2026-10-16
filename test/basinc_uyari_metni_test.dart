// Owner, TestFlight 2026-10-16 11:48: İstasyon basıncı 1014.3 hPa taken
// with the phone barometer at 07:57 (sea level), İrtifa now 359 m. The
// warning called it a sea-level value and named "Basınç al" while the
// button read "Basıncı yenile". An old phone reading now says when it was
// taken and names the button as it is shown; every other message names
// the button's current label too.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-basinc-uyari',
  name: 'Basınç',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _pressureKey = Key('environment-phone-pressure');
const _weatherKey = Key('environment-fill-weather');
const _warning = Key('environment-pressure-warning');
const _weatherStatus = Key('environment-weather-status');

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

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

String _message(WidgetTester tester, Key key) =>
    tester.widget<MenzilNotice>(find.byKey(key)).message;

String _buttonLabel(WidgetTester tester) =>
    tester.widget<MenzilSecondaryButton>(find.byKey(_pressureKey)).label;

class _Rig {
  final TestClock clock;
  final TestPressure pressure;
  _Rig(DateTime now, double hpa)
    : clock = TestClock(now),
      pressure = TestPressure(PressureRead(hpa));
  void at(DateTime t) => clock.current = t;
}

Future<void> _pump(WidgetTester tester, _Rig rig) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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
        weather: TestWeather(observation(fetchedAt: rig.clock.current.toUtc())),
        pressure: rig.pressure,
        clock: rig.clock,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Lets the 30-minute freshness timer run out so no Timer stays pending.
Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(hours: 1));
  expect(tester.takeException(), isNull);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('old phone reading (07:57, now 11:47): says when, names '
      '"Basıncı yenile", no sea-level text', (tester) async {
    final rig = _Rig(DateTime(2026, 10, 16, 7, 57), 1014.3);
    await _pump(tester, rig);
    await _tap(tester, _pressureKey);
    rig.at(DateTime(2026, 10, 16, 11, 47));
    await _type(tester, BallisticsFieldKeys.altitude, '359');

    expect(_buttonLabel(tester), 'Basıncı yenile');
    final m = _message(tester, _warning);
    expect(
      m,
      'Bu basınç 07:57\'de alındı. 359 m irtifada yaklaşık 971 hPa '
      'beklenir; yer değiştirdiyseniz "Basıncı yenile"ye basın.',
    );
    expect(m, contains('07:57'));
    expect(m, contains('Basıncı yenile'));
    expect(m, isNot(contains('Basınç al')));
    expect(m, isNot(contains('deniz seviyesi')));
    await _finish(tester);
  });

  testWidgets('old phone reading from yesterday: date and time', (
    tester,
  ) async {
    final rig = _Rig(DateTime(2026, 10, 15, 7, 57), 1014.3);
    await _pump(tester, rig);
    await _tap(tester, _pressureKey);
    rig.at(DateTime(2026, 10, 16, 11, 47));
    await _type(tester, BallisticsFieldKeys.altitude, '359');

    final m = _message(tester, _warning);
    expect(m, startsWith('Bu basınç 15.10.2026 07:57\'de alındı.'));
    expect(m, contains('"Basıncı yenile"ye basın'));
    await _finish(tester);
  });

  testWidgets('old phone reading, too low: same wording', (tester) async {
    final rig = _Rig(DateTime(2026, 10, 16, 7, 57), 912.4);
    await _pump(tester, rig);
    await _tap(tester, _pressureKey);
    rig.at(DateTime(2026, 10, 16, 11, 47));
    await _type(tester, BallisticsFieldKeys.altitude, '0');

    expect(
      _message(tester, _warning),
      'Bu basınç 07:57\'de alındı. 0 m irtifada yaklaşık 1013 hPa '
      'beklenir; yer değiştirdiyseniz "Basıncı yenile"ye basın.',
    );
    await _finish(tester);
  });

  testWidgets('fresh phone reading (5 min): sea-level text naming the '
      'label shown', (tester) async {
    final rig = _Rig(DateTime(2026, 10, 16, 11, 42), 1014.3);
    await _pump(tester, rig);
    await _tap(tester, _pressureKey);
    rig.at(DateTime(2026, 10, 16, 11, 47));
    await _type(tester, BallisticsFieldKeys.altitude, '359');

    expect(_buttonLabel(tester), 'Basınç alındı');
    final m = _message(tester, _warning);
    expect(m, contains('deniz seviyesi basıncı'));
    expect(m, contains('"Basınç alındı" düğmesini'));
    expect(m, isNot(contains('"Basınç al"')));
    await _finish(tester);
  });

  testWidgets('typed 1014.3, never fetched: original text, "Basınç al"', (
    tester,
  ) async {
    final rig = _Rig(DateTime(2026, 10, 16, 11, 47), 1014.3);
    await _pump(tester, rig);
    await _type(tester, BallisticsFieldKeys.pressure, '1014.3');
    await _type(tester, BallisticsFieldKeys.altitude, '359');

    expect(_buttonLabel(tester), 'Basınç al');
    expect(
      _message(tester, _warning),
      '359 m irtifada gerçek basınç yaklaşık 971 hPa olur; girilen değer '
      'deniz seviyesi basıncı olabilir. Hava durumu uygulamasındaki basıncı '
      'istasyon basıncına çevirin ya da "Basınç al" düğmesini kullanın.',
    );
    await _finish(tester);
  });

  testWidgets('typed too low: original text', (tester) async {
    final rig = _Rig(DateTime(2026, 10, 16, 11, 47), 1014.3);
    await _pump(tester, rig);
    await _type(tester, BallisticsFieldKeys.pressure, '700');
    await _type(tester, BallisticsFieldKeys.altitude, '0');

    expect(
      _message(tester, _warning),
      '0 m irtifa için basınç çok düşük (yaklaşık 1013 hPa beklenir). '
      'Basıncı ve irtifayı kontrol edin.',
    );
    await _finish(tester);
  });

  testWidgets('weather status names the pressure button as it is shown', (
    tester,
  ) async {
    final rig = _Rig(DateTime(2026, 10, 16, 11, 47), 1014.3);
    await _pump(tester, rig);
    await _tap(tester, _weatherKey);
    expect(_message(tester, _weatherStatus), contains('"Basınç al"'));

    await _tap(tester, _pressureKey);
    expect(_buttonLabel(tester), 'Basınç alındı');
    final m = _message(tester, _weatherStatus);
    expect(m, contains('Basınç için "Basınç alındı"'));
    expect(m, isNot(contains('{')));

    rig.at(DateTime(2026, 10, 16, 12, 30));
    await _type(tester, BallisticsFieldKeys.altitude, '0');
    expect(_buttonLabel(tester), 'Basıncı yenile');
    expect(
      _message(tester, _weatherStatus),
      contains('Basınç için "Basıncı yenile"'),
    );
    await _finish(tester);
  });
}
