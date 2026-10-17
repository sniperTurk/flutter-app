// Pro Ayarlar > Tüfek düzeltmeleri summary (owner, 2026-10-15 21:13): with
// every box empty it said "1 ayar açık". The summary counts only what is
// entered in the box's own fields; spin drift (always on, no switch) and the
// powder values from Profil > Mühimmat are not counted.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/pro_sections.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_oz',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_oz',
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

/// Barut sıcaklığı is set on Profil > Mühimmat: before the fix this alone
/// was counted as a second "ayar açık" on a firearm.
const _profile = RifleProfile(
  id: 'p-oz',
  name: 'Özet',
  rifleId: 'manual_rifle_oz',
  ammunitionId: 'manual_ammo_oz',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: 1.5,
  powderTempReferenceC: 20,
);

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  // The summary shows only while the box is closed.
  Future<String?> summary(WidgetTester tester) async {
    if (find.byKey(const Key('pro-summary-rifle')).evaluate().isEmpty) {
      final header = find.byKey(const Key('pro-section-rifle'));
      await tester.ensureVisible(header);
      await tester.pumpAndSettle();
      await tapProHeader(tester, header);
    }
    return tester.widget<Text>(find.byKey(const Key('pro-summary-rifle'))).data;
  }

  Future<void> type(WidgetTester tester, Key key, String v) async {
    await openProFor(tester, key);
    final f = find.descendant(
      of: find.byKey(key),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(f);
    await tester.enterText(f, v);
    await tester.pumpAndSettle();
  }

  testWidgets('Tüfek düzeltmeleri counts only its own entered boxes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 3000) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: const Scaffold(
          body: BallisticsScreen(profile: _profile, view: BallisticsView.pro),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fresh profile, every box empty.
    expect(await summary(tester), 'kapalı');

    await type(tester, const Key('pro-turret-scale'), '1,02');
    expect(await summary(tester), '1 ayar açık');

    await type(tester, const Key('pro-zero-up'), '1');
    expect(await summary(tester), '2 ayar açık');

    // Mühimmat sıcaklığı has its own box since 2026-10-17 (owner): it is
    // counted there, not here.
    await type(tester, const Key('env-ammo-temp'), '30');
    expect(await summary(tester), '2 ayar açık');

    // Clearing the boxes brings it back to "kapalı".
    await type(tester, const Key('pro-turret-scale'), '');
    await type(tester, const Key('pro-zero-up'), '');
    await type(tester, const Key('env-ammo-temp'), '');
    expect(await summary(tester), 'kapalı');
  });
}
