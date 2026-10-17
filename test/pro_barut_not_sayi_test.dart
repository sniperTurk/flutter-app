// Pro barut notu (owner, 2026-10-17): only the layout and the note texts
// changed; the powder-temperature correction must give the same numbers as
// before. This file runs unchanged on main and on fix/pro-barut-not; the
// printed BARUT_SAYI lines are compared in docs/reports/pro_barut_not.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/pro_sections.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_bn',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_bn',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test 168',
  'model': '',
  'caliberMm': 7.62,
  'grain': 168,
  'ammoType': 'bullet',
  'bc': 0.462,
  'bcModel': 'g1',
};

const _withCoef = RifleProfile(
  id: 'p-bn',
  name: 'BN',
  rifleId: 'manual_rifle_bn',
  ammunitionId: 'manual_ammo_bn',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: 1.5,
  powderTempReferenceC: 20,
);
const _noCoef = RifleProfile(
  id: 'p-bn',
  name: 'BN',
  rifleId: 'manual_rifle_bn',
  ammunitionId: 'manual_ammo_bn',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

const _ammoKey = Key('env-ammo-temp');

Widget _app(RifleProfile p, BallisticsView view) => MaterialApp(
  theme: MenzilTheme.light(),
  home: Scaffold(
    body: BallisticsScreen(profile: p, view: view),
  ),
);

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  /// Hedef's required elevation at 600 m with Mühimmat sıcaklığı [ammo]
  /// (empty = the air temperature, 15 °C), and Pro's "Bugünkü hız" text (or null).
  Future<(double, String?)> solve(
    WidgetTester tester,
    RifleProfile p,
    String ammo,
  ) async {
    // Hava sıcaklığı 15 °C on Hava Durumu (kept for the profile).
    await tester.pumpWidget(_app(p, BallisticsView.environment));
    await tester.pumpAndSettle();
    final air = _field(BallisticsFieldKeys.temperature);
    await tester.ensureVisible(air);
    await tester.enterText(air, '15');
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(p, BallisticsView.pro));
    await tester.pumpAndSettle();
    await openProFor(tester, _ammoKey);
    final a = _field(_ammoKey);
    await tester.ensureVisible(a);
    await tester.enterText(a, ammo);
    await tester.pumpAndSettle();
    final range = _field(const Key('pro-shot-range'));
    await tester.ensureVisible(range);
    await tester.enterText(range, '600');
    await tester.pumpAndSettle();
    final todayFinder = find.byKey(const Key('pro-powder-today'));
    final today = todayFinder.evaluate().isEmpty
        ? null
        : tester.widget<Text>(todayFinder).data;
    await tester.pumpWidget(_app(p, BallisticsView.shot));
    await tester.pumpAndSettle();
    final up = tester
        .widget<ScopeDialView>(find.byType(ScopeDialView))
        .requiredUp!;
    return (up, today);
  }

  testWidgets('powder correction numbers, fixed firearm profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 3000) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final coefEmpty = await solve(tester, _withCoef, '');
    final coef35 = await solve(tester, _withCoef, '35');
    final noCoefEmpty = await solve(tester, _noCoef, '');
    final noCoef35 = await solve(tester, _noCoef, '35');
    for (final (name, r) in [
      ('katsayili_bos', coefEmpty),
      ('katsayili_35', coef35),
      ('katsayisiz_bos', noCoefEmpty),
      ('katsayisiz_35', noCoef35),
    ]) {
      // ignore: avoid_print
      print('BARUT_SAYI:$name:up600=${r.$1.toStringAsFixed(6)}:${r.$2}');
    }

    // With Barut katsayısı 1,5 %/15 °C and Hız ölçüm sıcaklığı 20 °C, a
    // 35 °C cartridge: 800 × (1 + 0,015 × 15 / 15) = 812 m/s.
    expect(
      coef35.$2,
      contains('${UnitSystem.mpsToFps(812).toStringAsFixed(0)} fps'),
    );
    // Air 15 °C, reference 20 °C: 800 × (1 − 0,015 × 5 / 15) = 796 m/s.
    expect(
      coefEmpty.$2,
      contains('${UnitSystem.mpsToFps(796).toStringAsFixed(0)} fps'),
    );
    // Faster: less elevation than the same profile at the air temperature.
    expect(coef35.$1, lessThan(coefEmpty.$1));
    // Without the two profile values the cartridge temperature changes
    // nothing and there is no "Bugünkü hız".
    expect(noCoef35.$1, noCoefEmpty.$1);
    expect(noCoef35.$2, isNull);
    expect(noCoefEmpty.$2, isNull);
    expect(tester.takeException(), isNull);
  });
}
