// TEMPORARY (PR #368 evidence, not for merge): prints the Hedef requiredUp
// of an older PCP profile on main, so the branch can pin "same as main".
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

const _pcpRifle = <String, dynamic>{
  'id': 'manual_rifle_pcpm',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'PCPM',
  'model': 'Test',
  'caliberMm': 5.5,
  'barrelLengthMm': 500,
  'twistDirection': 'right',
  'twistRateIn': 18,
};

const _pcpAmmo = <String, dynamic>{
  'id': 'manual_ammo_pcpm',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'PCPM 18',
  'model': '',
  'caliberMm': 5.5,
  'grain': 18,
  'ammoType': 'pellet',
  'bc': 0.031,
  'bcModel': 'g1',
};

void main() {
  testWidgets('PCP_OLD_GOLDEN on main', (tester) async {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_pcpRifle, _pcpAmmo]),
    );
    final p = RifleProfile(
      id: 'eski',
      name: 'Eski PCP',
      rifleId: 'manual_rifle_pcpm',
      ammunitionId: 'manual_ammo_pcpm',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: UnitSystem.fpsToMps(885.8),
      zeroRangeM: 30,
      sightHeightMm: 50,
      tubePressureBar: 250,
      pressureBar: 150,
    );
    tester.view.physicalSize = const Size(430, 3000) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: BallisticsScreen(profile: p, view: BallisticsView.shot),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final up = tester.widget<ScopeDialView>(find.byType(ScopeDialView)).requiredUp;
    // ignore: avoid_print
    print('PCP_OLD_GOLDEN U$up');
    expect(up, isNotNull);
  });
}
