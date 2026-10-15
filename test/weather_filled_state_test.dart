// Owner, TestFlight 2026-10-13 08:36: a saved profile's Hava Durumu showed
// the fetched values but "Konumdan canlı hava verisi al" was not orange.
// A fetched value keeps the orange "…alındı" state until Sıfırla, through
// tabs, the pressure button and an app restart (owner, 2026-10-12).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
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
);

const _weatherButton = Key('environment-fill-weather');
const _pressureButton = Key('environment-phone-pressure');

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(MenzilBottomNavigation),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _press(WidgetTester tester, Key key) async {
  final button = find.byKey(key);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

bool _orange(WidgetTester tester) =>
    tester.widget<MenzilSecondaryButton>(find.byKey(_weatherButton)).active;

Future<void> _pump(
  WidgetTester tester,
  MemoryProfileStore store,
  MemoryActiveProfileStore active,
) async {
  await tester.pumpWidget(
    host(
      HomeScreen(
        key: UniqueKey(),
        profileStore: store,
        activeProfileStore: active,
      ),
      services: testServices(
        location: TestLocation(const LocationFix(39.9, 32.8, altitudeM: 900)),
        weather: TestWeather(
          observation(fetchedAt: DateTime.utc(2026, 10, 13, 5, 30)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _tab(tester, 'Hava Durumu');
}

Future<(MemoryProfileStore, MemoryActiveProfileStore)> _fetched(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = MemoryProfileStore();
  final active = MemoryActiveProfileStore();
  await store.save(_profile);
  active.value = _profile.id;
  await _pump(tester, store, active);
  expect(_orange(tester), isFalse);
  await _press(tester, _weatherButton);
  expect(_orange(tester), isTrue);
  return (store, active);
}

void main() {
  for (final away in ['Profil', 'Pro', 'Hedef', 'Araçlar']) {
    testWidgets('stays orange through Hava Durumu → $away → back', (
      tester,
    ) async {
      await _fetched(tester);
      await _tab(tester, away);
      await _tab(tester, 'Hava Durumu');
      expect(_orange(tester), isTrue);
    });
  }

  testWidgets('stays orange after "Basınç al"', (tester) async {
    await _fetched(tester);
    await _press(tester, _pressureButton);
    expect(_orange(tester), isTrue);
    await _tab(tester, 'Profil');
    await _tab(tester, 'Hava Durumu');
    expect(_orange(tester), isTrue);
  });

  testWidgets('stays orange after the app restarts', (tester) async {
    final (store, active) = await _fetched(tester);
    await _press(tester, _pressureButton);
    // Give the debounced save a turn, then start the app again on the same
    // storage.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await _pump(tester, store, active);
    expect(_orange(tester), isTrue);
  });

  Finder field(Key key) =>
      find.descendant(of: find.byKey(key), matching: find.byType(TextField));

  Future<void> type(WidgetTester tester, Key key, String v) async {
    await tester.ensureVisible(field(key));
    await tester.pumpAndSettle();
    await tester.enterText(field(key), v);
    await tester.pumpAndSettle();
  }

  bool pressureOrange(WidgetTester tester) =>
      tester.widget<MenzilSecondaryButton>(find.byKey(_pressureButton)).active;

  // Owner, 2026-10-13: only a typed Sıcaklık or Bağıl nem turns the weather
  // button gray; wind and İrtifa never do.
  testWidgets('a typed Rüzgâr hızı keeps the weather button orange', (
    tester,
  ) async {
    await _fetched(tester);
    await type(tester, BallisticsFieldKeys.wind, '7');
    expect(_orange(tester), isTrue);
  });

  // Owner, 2026-10-14: İrtifa has its own card; a typed İrtifa leaves both
  // the weather and the pressure button as they are.
  testWidgets('a typed İrtifa clears neither the weather nor the pressure', (
    tester,
  ) async {
    await _fetched(tester);
    await _press(tester, _pressureButton);
    expect(pressureOrange(tester), isTrue);
    await type(tester, BallisticsFieldKeys.altitude, '850');
    expect(_orange(tester), isTrue);
    expect(pressureOrange(tester), isTrue);
  });

  testWidgets('a typed Bağıl nem turns the weather button gray', (
    tester,
  ) async {
    await _fetched(tester);
    await type(tester, BallisticsFieldKeys.humidity, '40');
    expect(_orange(tester), isFalse);
  });
}
