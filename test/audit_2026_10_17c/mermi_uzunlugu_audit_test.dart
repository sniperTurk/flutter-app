// Pre-TestFlight audit 2026-10-17c — #379 (main 2101b3f): bullet length
// for spin drift / aerodynamic jump now comes from Profil → Mühimmat →
// Mermi uzunluğu, with the old Pro "Mermi uzunluğu" (shot settings
// 'bulletLength') as fallback.
//
// Guard (no finding): a PCP slug whose length was only in Pro gives the
// same turret windage and spin drift line as before (Pro value used), and
// the same length in the profile gives the same numbers.
//
// DEN17C-1 (ORTA, open): a PCP ammunition record saved before 2026-10-13
// 23:32 may still hold a length (the box was hidden then, the value kept
// and NOT used: TestFlight 112 used only Pro). With a different Pro value,
// main now uses the hidden record value, so spin drift, aerodynamic jump
// and the Yan kule clicks change silently for a profile whose length was
// in Pro (ballistics_screen.dart _bulletLengthMm: profile first). The
// test below is skipped until fixed or the owner accepts the change.
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
  'id': 'manual_rifle_den17c_mu',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'DEN17C',
  'model': 'Slug',
  'caliberMm': 5.5,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 18,
};

const _slug = <String, dynamic>{
  'id': 'manual_ammo_den17c_mu',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'DEN17C slug',
  'model': '',
  'caliberMm': 5.5,
  'grain': 25,
  'ammoType': 'slug',
  'bc': 0.07,
  'bcModel': 'g1',
};

const _profile = RifleProfile(
  id: 'p-den17c-mu',
  name: 'Uzunluk',
  rifleId: 'manual_rifle_den17c_mu',
  ammunitionId: 'manual_ammo_den17c_mu',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 50,
);

Future<({double right, String? note})> _shot(
  WidgetTester tester, {
  double? recordLength,
  String pro = '',
}) async {
  tester.view.physicalSize = const Size(430, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    ShotSettingsStore.keyFor(_profile.id): jsonEncode(
      ShotSettings(bulletLengthText: pro).toJson(),
    ),
  });
  CatalogRepository.installUserCatalog(
    UserCatalog.fromManualEntries([
      _rifle,
      {..._slug, if (recordLength != null) 'lengthMm': recordLength},
    ]),
  );
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: const Scaffold(
        body: BallisticsScreen(profile: _profile, view: BallisticsView.shot),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final note = find.byKey(const Key('shot-spin-drift'));
  return (
    right: tester.widget<ScopeDialView>(find.byType(ScopeDialView)).requiredRight,
    note: note.evaluate().isEmpty ? null : tester.widget<Text>(note).data,
  );
}

void main() {
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('PCP slug, length only in Pro = the same length in Profil', (
    tester,
  ) async {
    final pro = await _shot(tester, pro: '15');
    final record = await _shot(tester, recordLength: 15);
    expect(pro.note, isNotNull);
    expect(record.note, pro.note);
    expect(record.right, pro.right);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'DEN17C-1: hidden old record length + Pro value → TestFlight 112 '
    'numbers (Pro value)',
    (tester) async {
      final tf112 = await _shot(tester, pro: '15');
      final both = await _shot(tester, recordLength: 9, pro: '15');
      // TestFlight 112 used only Pro (15 mm). Today the hidden 9 mm wins.
      expect(both.note, tf112.note);
      expect(both.right, tf112.right);
    },
    skip: true, // DEN17C-1 (ORTA, open)
  );
}
