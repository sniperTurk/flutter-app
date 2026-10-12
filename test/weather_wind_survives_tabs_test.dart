// Hava Durumu → "Konumdan canlı hava verisi al" → another tab → back
// (owner, TestFlight 79/80, 2026-10-12): the wind boxes (Rüzgâr hızı,
// Rüzgâr yönü) and Rüzgâr düzeltmesi (En yüksek rüzgâr, Yol ortası,
// Hedefte; on Pro Ayarlar again since 2026-10-12) must keep their values
// like the atmosphere boxes do. The weather service gives no gust: the top
// wind box starts empty and "Rüzgâr düzeltmesi al" writes wind × 1,5.
// Nothing is fetched before a button is pressed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/features/tools/tools_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/pro_sections.dart';
import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-wind',
  name: 'Rüzgâr',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

/// The same rifle after Araçlar → Hız Doğrulama wrote a trued velocity:
/// the shell re-keys the workspace on the profile's values.
const _trued = RifleProfile(
  id: 'p-wind',
  name: 'Rüzgâr',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 280,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _windMax = Key('pro-wind-max');
const _windMid = Key('pro-wind-mid');
const _windFar = Key('pro-wind-far');

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(_field(key)).controller!.text;

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

typedef _Home = ({
  TestWeather weather,
  MemoryProfileStore store,
  MemoryActiveProfileStore active,
});

Future<_Home> _pumpHome(
  WidgetTester tester, {
  required bool withProfile,
}) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // The app's own storage (unit preference, Pro settings) as on a phone.
  SharedPreferences.setMockInitialValues({});
  final store = MemoryProfileStore();
  final active = MemoryActiveProfileStore();
  if (withProfile) {
    await store.save(_profile);
    active.value = _profile.id;
  }
  final weather = TestWeather(
    observation(fetchedAt: DateTime.utc(2026, 10, 12, 0, 57)),
  );
  await tester.pumpWidget(
    host(
      HomeScreen(profileStore: store, activeProfileStore: active),
      services: testServices(
        location: TestLocation(const LocationFix(39.9, 32.8, altitudeM: 900)),
        weather: weather,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _tab(tester, 'Hava Durumu');
  // Owner rule: no location / weather data before the button is pressed.
  expect(weather.calls, 0);
  final button = find.byKey(const Key('environment-fill-weather'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(weather.calls, 1);
  return (weather: weather, store: store, active: active);
}

void _expectAtmosphere(WidgetTester tester) {
  expect(_text(tester, BallisticsFieldKeys.temperature), '18.5');
  expect(_text(tester, BallisticsFieldKeys.humidity), '55');
  // İrtifa comes from "Basıncı telefondan al", not the weather button
  // (owner, 2026-10-12).
  expect(_text(tester, BallisticsFieldKeys.altitude), '');
}

double _number(WidgetTester tester, Key key) =>
    double.parse(_text(tester, key));

/// Rüzgâr düzeltmesi lives on Pro Ayarlar (owner, 2026-10-12): these open
/// the Pro tab and its box, and stay there.
Future<String> _proText(WidgetTester tester, Key key) async {
  await _tab(tester, 'Pro');
  await openProFor(tester, key);
  return _text(tester, key);
}

/// "Rüzgâr düzeltmesi al" on Pro (owner, 2026-10-12: the box starts empty).
Future<String> _proFill(WidgetTester tester) async {
  await _tab(tester, 'Pro');
  await openProFor(tester, _windMax);
  final button = find.byKey(const Key('pro-wind-max-fill'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  return _text(tester, _windMax);
}

Future<void> _proType(WidgetTester tester, Key key, String value) async {
  await _tab(tester, 'Pro');
  await openProFor(tester, key);
  await _type(tester, key, value);
}

State _workspace(WidgetTester tester) =>
    tester.state(find.byType(BallisticsScreen));

void main() {
  for (final away in ['Araçlar', 'Profil', 'Pro', 'Hedef']) {
    testWidgets('profile: wind boxes survive Hava Durumu → $away → back', (
      tester,
    ) async {
      final (:weather, store: _, active: _) = await _pumpHome(
        tester,
        withProfile: true,
      );
      _expectAtmosphere(tester);
      expect(_text(tester, BallisticsFieldKeys.wind), '5.0');
      await _type(tester, BallisticsFieldKeys.windDirection, '3');
      // No gust from the service: "Rüzgâr düzeltmesi al" writes wind × 1,5.
      expect(await _proText(tester, _windMax), '');
      expect(await _proFill(tester), '7.5');
      await _proType(tester, _windMid, '4');
      await _proType(tester, _windFar, '6');

      await _tab(tester, 'Hava Durumu');
      await _tab(tester, away);
      await _tab(tester, 'Hava Durumu');

      _expectAtmosphere(tester);
      expect(_text(tester, BallisticsFieldKeys.wind), '5.0');
      expect(_text(tester, BallisticsFieldKeys.windDirection), '3');
      expect(await _proText(tester, _windMax), '7.5');
      expect(_text(tester, _windMid), '4');
      expect(_text(tester, _windFar), '6');
      // Coming back fetches nothing by itself.
      expect(weather.calls, 1);
    });
  }

  testWidgets('profile: a typed En yüksek rüzgâr is kept, not replaced', (
    tester,
  ) async {
    await _pumpHome(tester, withProfile: true);
    expect(await _proFill(tester), '7.5');
    await _proType(tester, _windMax, '9');
    await _tab(tester, 'Araçlar');
    await _tab(tester, 'Hava Durumu');
    expect(_text(tester, BallisticsFieldKeys.wind), '5.0');
    expect(await _proText(tester, _windMax), '9');
    // A new fill keeps the shooter's own top wind too.
    await _tab(tester, 'Hava Durumu');
    final button = find.byKey(const Key('environment-fill-weather'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(await _proText(tester, _windMax), '9');
  });

  for (final away in ['Araçlar', 'Profil', 'Pro', 'Hedef']) {
    testWidgets('no profile: wind boxes survive Hava Durumu → $away → back', (
      tester,
    ) async {
      final (:weather, store: _, active: _) = await _pumpHome(
        tester,
        withProfile: false,
      );
      _expectAtmosphere(tester);
      expect(_text(tester, BallisticsFieldKeys.wind), '5.0');
      await _type(tester, BallisticsFieldKeys.windDirection, '3');

      await _tab(tester, away);
      await _tab(tester, 'Hava Durumu');

      _expectAtmosphere(tester);
      expect(
        double.parse(_text(tester, BallisticsFieldKeys.wind)),
        closeTo(5.0, 1e-9),
      );
      expect(_text(tester, BallisticsFieldKeys.windDirection), '3');
      expect(weather.calls, 1);
    });
  }

  testWidgets('profile: a re-created workspace (Araçlar wrote the profile) '
      'keeps Hava Durumu and Rüzgâr düzeltmesi', (tester) async {
    final (:weather, :store, active: _) = await _pumpHome(
      tester,
      withProfile: true,
    );
    await _type(tester, BallisticsFieldKeys.windDirection, '3');
    expect(await _proFill(tester), '7.5');
    await _proType(tester, _windMid, '4');
    await _proType(tester, _windFar, '6');
    final before = _workspace(tester);

    // Araçlar → a tool (Hız Doğrulama) saves the profile; when its page
    // closes the shell reloads the profiles.
    await _tab(tester, 'Araçlar');
    await store.save(_trued);
    await tester
        .widget<ToolsScreen>(find.byType(ToolsScreen))
        .onProfilesChanged!();
    await tester.pumpAndSettle();
    await _tab(tester, 'Hava Durumu');

    // The path really builds a new workspace.
    expect(_workspace(tester), isNot(same(before)));
    _expectAtmosphere(tester);
    expect(_number(tester, BallisticsFieldKeys.wind), closeTo(5.0, 1e-9));
    expect(_text(tester, BallisticsFieldKeys.windDirection), '3');
    expect(double.parse(await _proText(tester, _windMax)), closeTo(7.5, 1e-9));
    expect(_text(tester, _windMid), '4');
    expect(_text(tester, _windFar), '6');
    expect(weather.calls, 1);
  });

  testWidgets('profile: a typed En yüksek rüzgâr survives a re-created '
      'workspace', (tester) async {
    final (weather: _, :store, active: _) = await _pumpHome(
      tester,
      withProfile: true,
    );
    await _proType(tester, _windMax, '9');
    await _tab(tester, 'Araçlar');
    await store.save(_trued);
    await tester
        .widget<ToolsScreen>(find.byType(ToolsScreen))
        .onProfilesChanged!();
    await tester.pumpAndSettle();
    await _tab(tester, 'Hava Durumu');
    expect(_number(tester, BallisticsFieldKeys.wind), closeTo(5.0, 1e-9));
    expect(await _proText(tester, _windMax), '9');
  });

  testWidgets('no profile → first profile: the weather and wind speed carry '
      'over, the wind direction does not', (
    tester,
  ) async {
    final (:weather, :store, :active) = await _pumpHome(
      tester,
      withProfile: false,
    );
    await _type(tester, BallisticsFieldKeys.windDirection, '3');
    await _tab(tester, 'Profil');
    await store.save(_profile);
    active.value = _profile.id;
    await tester
        .widget<ProfilesScreen>(find.byType(ProfilesScreen))
        .onProfilesChanged!();
    await tester.pumpAndSettle();
    await _tab(tester, 'Hava Durumu');
    _expectAtmosphere(tester);
    expect(_number(tester, BallisticsFieldKeys.wind), closeTo(5.0, 1e-9));
    // Rüzgâr yönü depends on where the shooter faces; a new profile starts
    // without it (owner, 2026-10-13).
    expect(_text(tester, BallisticsFieldKeys.windDirection), '');
    // Rüzgâr düzeltmesi starts empty until "Rüzgâr düzeltmesi al".
    expect(await _proText(tester, _windMax), '');
    expect(double.parse(await _proFill(tester)), closeTo(7.5, 1e-9));
    expect(weather.calls, 1);
  });
}
