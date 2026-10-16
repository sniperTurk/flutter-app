// Temporary probe (deleted after reading): prints main's numbers as a
// failing expectation so the value shows in the check-run annotation.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_mb',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_mb',
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
const _firearm = RifleProfile(
  id: 'p-mb',
  name: 'MB',
  rifleId: 'manual_rifle_mb',
  ammunitionId: 'manual_ammo_mb',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: 1.5,
  powderTempReferenceC: 15,
);

Widget _app(BallisticsView view) => MaterialApp(
  theme: MenzilTheme.light(),
  home: Scaffold(body: BallisticsScreen(profile: _firearm, view: view)),
);

void main() {
  setUp(() {
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  for (final t in ['35', '', '-10']) {
    testWidgets('PROBE ammo=$t', (tester) async {
      SharedPreferences.setMockInitialValues({
        ShotSettingsStore.keyFor(_firearm.id): jsonEncode(
          ShotSettings(ammoTempText: t).toJson(),
        ),
      });
      tester.view.physicalSize = const Size(430, 3000) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(BallisticsView.pro));
      await tester.pumpAndSettle();
      final range = find.descendant(
        of: find.byKey(const Key('pro-shot-range')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(range);
      await tester.enterText(range, '600');
      await tester.pump();
      await tester.pumpWidget(_app(BallisticsView.shot));
      await tester.pumpAndSettle();
      final d = tester.widget<ScopeDialView>(find.byType(ScopeDialView));
      expect(
        'GOLDEN ammo=$t up=${d.requiredUp} right=${d.requiredRight} '
        'range=${d.rangeM}',
        'x',
      );
    });
  }
}
