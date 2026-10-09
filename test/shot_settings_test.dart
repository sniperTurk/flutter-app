// Pro Ayarlar values survive a restart; an implausible pressure is flagged
// (owner, 2026-10-09).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _profile = RifleProfile(
  id: 'p-shot',
  name: 'Kayıt',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

Widget _app(BallisticsView view, {Key? key}) => MaterialApp(
  theme: MenzilTheme.light(),
  home: Scaffold(
    body: BallisticsScreen(key: key, profile: _profile, view: view),
  ),
);

Future<void> _sized(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  test('damaged values fall back to level / off', () {
    final s = ShotSettings.fromJson({
      'incline': 'x',
      'cant': 999,
      'coriolis': 'yes',
      'latitude': 39.9,
    });
    expect(s.inclineDeg, 0);
    expect(s.cantDeg, 0);
    expect(s.coriolisOn, isFalse);
    expect(s.latitudeText, '');
    expect(ShotSettings.fromJson(null).inclineDeg, 0);
  });

  testWidgets('saved incline, cant and Coriolis come back on Pro', (
    tester,
  ) async {
    await _sized(tester);
    SharedPreferences.setMockInitialValues({
      ShotSettingsStore.keyFor('p-shot'): jsonEncode(
        const ShotSettings(
          inclineDeg: -12,
          cantDeg: 4,
          coriolisOn: true,
          latitudeText: '39.9',
          azimuthText: '135',
        ).toJson(),
      ),
    });
    await tester.pumpWidget(_app(BallisticsView.pro));
    await tester.pumpAndSettle();
    expect(find.text('∠ −12°'), findsOneWidget);
    expect(find.text('4° sağa'), findsOneWidget);
    expect(find.byKey(const Key('pro-latitude')), findsOneWidget);
    final lat = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('pro-latitude')),
        matching: find.byType(TextField),
      ),
    );
    expect(lat.controller!.text, '39.9');
  });

  testWidgets('a change is written for the next start', (tester) async {
    await _sized(tester);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_app(BallisticsView.pro));
    await tester.pumpAndSettle();
    final sw = find.byKey(const Key('pro-coriolis-switch'));
    await tester.ensureVisible(sw);
    await tester.tap(sw);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ShotSettingsStore.keyFor('p-shot'));
    expect(raw, isNotNull);
    expect(ShotSettings.fromJson(jsonDecode(raw!)).coriolisOn, isTrue);
  });

  testWidgets('sea-level pressure at altitude is flagged', (tester) async {
    await _sized(tester);
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    Future<void> type(Key key, String v) async {
      final f = find.descendant(
        of: find.byKey(key),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(f);
      await tester.enterText(f, v);
      await tester.pump();
    }

    const warning = Key('environment-pressure-warning');
    await type(BallisticsFieldKeys.altitude, '1000');
    await type(BallisticsFieldKeys.pressure, '1013');
    expect(find.byKey(warning), findsOneWidget);
    expect(find.textContaining('deniz seviyesi basıncı'), findsOneWidget);
    await type(BallisticsFieldKeys.pressure, '900');
    expect(find.byKey(warning), findsNothing);
    await type(BallisticsFieldKeys.pressure, '700');
    expect(find.byKey(warning), findsOneWidget);
  });
}
