// Hava Durumu (owner, TestFlight 2026-10-13: "Hava durumu turuncu kutu
// seçili gelmiyor"): after "Konumdan canlı hava verisi al" the button stays
// orange ("…alındı") while its own boxes (Sıcaklık, Bağıl nem) keep the
// service's values: typing the wind or İrtifa, other tabs and a restart do
// not turn it gray. İrtifa belongs to "Basıncı telefondan al".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/pressure_sensor.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-orange',
  name: 'Turuncu',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _weatherDone = 'Konumdan canlı hava verisi alındı';
const _pressureDone = 'Basınç telefondan alındı';

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, Key key, String value) async {
  await tester.ensureVisible(_field(key));
  await tester.pumpAndSettle();
  await tester.enterText(_field(key), value);
  await tester.pumpAndSettle();
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(MenzilBottomNavigation),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpHome(
  WidgetTester tester,
  MemoryProfileStore store,
  MemoryActiveProfileStore active, {
  Key? key,
}) async {
  await tester.pumpWidget(
    host(
      HomeScreen(key: key, profileStore: store, activeProfileStore: active),
      services: testServices(
        location: TestLocation(const LocationFix(39.9, 32.8, altitudeM: 900)),
        weather: TestWeather(
          observation(fetchedAt: DateTime.utc(2026, 10, 13, 1, 50)),
        ),
        pressure: TestPressure(const PressureRead(1013.6)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _tab(tester, 'Hava Durumu');
}

bool _orange(WidgetTester tester, Key key) =>
    tester.widget<MenzilSecondaryButton>(find.byKey(key)).active;

void main() {
  testWidgets('both buttons stay orange through wind, İrtifa, tabs, restart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final store = MemoryProfileStore();
    final active = MemoryActiveProfileStore();
    await store.save(_profile);
    active.value = _profile.id;
    await _pumpHome(tester, store, active);

    const weather = Key('environment-fill-weather');
    const pressure = Key('environment-phone-pressure');
    await _tap(tester, weather);
    await _tap(tester, pressure);
    expect(find.text(_weatherDone), findsOneWidget);
    expect(find.text(_pressureDone), findsOneWidget);

    // The wind boxes are not the weather button's to lose.
    await _type(tester, BallisticsFieldKeys.wind, '6');
    await _type(tester, BallisticsFieldKeys.windDirection, '3');
    expect(_orange(tester, weather), isTrue);

    for (final away in ['Hedef', 'Pro', 'Profil', 'Araçlar']) {
      await _tab(tester, away);
      await _tab(tester, 'Hava Durumu');
      expect(find.text(_weatherDone), findsOneWidget, reason: away);
      expect(find.text(_pressureDone), findsOneWidget, reason: away);
    }

    // A restart (fresh widget tree, same storage) reopens both orange.
    await _pumpHome(tester, store, active, key: UniqueKey());
    expect(find.text(_weatherDone), findsOneWidget);
    expect(find.text(_pressureDone), findsOneWidget);

    // İrtifa typed: only the pressure button turns gray.
    await _type(tester, BallisticsFieldKeys.altitude, '850');
    expect(_orange(tester, weather), isTrue);
    expect(_orange(tester, pressure), isFalse);
  });
}
