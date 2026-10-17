// KUL-10 (pre-TestFlight audit 2026-10-15c, high; PR #363,
// test/audit_2026_10_15c/diger_audit_test.dart, skipped there): Hız
// Doğrulama BC / Sürüklenme eğrisi solved a PCP with another velocity than
// the one Hedef zeroes and shoots with, so the applied BC made Hedef miss
// the truing range itself (about 0,8 mrad at 100 m).
//
// Owner, 2026-10-16: the "Basınca göre hız" table the original case was
// built on is deleted. Owner, 2026-10-17: a PCP calculates with the Tüfek
// card's Namlu çıkış hızı; En düşük / En yüksek namlu çıkış hızı are saved
// only. Same numbers as the original: Hedef's velocity 255 m/s (now the
// Namlu çıkış hızı), the other velocity 270 m/s (now the En düşük / En
// yüksek mean, which must not be used), 18 gr, G1 0,031, zero 30 m,
// truing at 100 m. Un-skipped: it must pass.
//
// References are hand calculations with the repository's own solver (the
// original audit's tools/denetim_2026_10_15c_diger.py: 6,89 mrad at 255
// m/s), not another ballistic app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/tools/truing_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';

import '../support/tool_fakes.dart';

const _k10Rifle = <String, dynamic>{
  'id': 'manual_rifle_k10',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'K10',
  'model': 'PCP',
  'caliberMm': 5.5,
  'barrelLengthMm': 500,
  'twistDirection': 'right',
  'twistRateIn': 18,
};

const _k10Ammo = <String, dynamic>{
  'id': 'manual_ammo_k10',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'K10 18',
  'model': '',
  'caliberMm': 5.5,
  'grain': 18,
  'ammoType': 'pellet',
  'bc': 0.031,
  'bcModel': 'g1',
};

/// Namlu çıkış hızı 255 m/s on the Tüfek card (what Hedef uses); En düşük
/// 265 and En yüksek 275 m/s on the Mühimmat card (mean 270 m/s, saved
/// only).
const _k10Profile = RifleProfile(
  id: 'k10',
  name: 'K10 PCP',
  rifleId: 'manual_rifle_k10',
  ammunitionId: 'manual_ammo_k10',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 255,
  pcpMinVelocityMps: 265,
  pcpMaxVelocityMps: 275,
  zeroRangeM: 30,
  sightHeightMm: 50,
  tubePressureBar: 120,
);

/// The truing page's default air (15 °C, 1013,25 hPa, %50).
const _truingAir = EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 50,
);

double _correction(double mps, double bc, double rangeM) =>
    const BallisticEngine()
        .solve(
          BallisticInput(
            muzzleVelocityMps: mps,
            grain: 18,
            zeroRangeM: 30,
            sightHeightMm: 50,
            rangesM: [rangeM],
            environment: _truingAir,
            ballisticCoefficient: bc,
            ballisticModel: BallisticModel.g1,
          ),
        )
        .single
        .correctionMrad;

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final f = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextField),
  );
  final target = f.evaluate().isEmpty ? find.byKey(Key(key)) : f;
  await tester.ensureVisible(target);
  await tester.enterText(target, text);
  await tester.pump();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('KUL-10 Hız Doğrulama BC on a PCP', () {
    test('hand check: the observation is a 255 m/s shot; at 270 m/s the '
        'same BC predicts less drop', () {
      final at255 = _correction(255, 0.031, 100);
      final at270 = _correction(270, 0.031, 100);
      expect(at255, closeTo(6.89, 0.15));
      expect(at270, lessThan(at255 - 0.5));
      expect(_k10Profile.muzzleVelocityMps, 255);
    });

    testWidgets('the applied BC reproduces the observation at the velocity '
        'Hedef uses (255 m/s)', (tester) async {
      await ManualCatalogStore().upsert(_k10Rifle);
      await ManualCatalogStore().upsert(_k10Ammo);
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries(await ManualCatalogStore().all()),
      );
      final store = MemoryProfileStore();
      await store.save(_k10Profile);
      tester.view.physicalSize = const Size(430, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final active = MemoryActiveProfileStore()..value = _k10Profile.id;
      await tester.pumpWidget(
        host(TruingScreen(profileStore: store, activeProfileStore: active)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Namlu çıkış hızı').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Balistik katsayı (BC)').last);
      await tester.pumpAndSettle();

      final observed = _correction(255, 0.031, 100);
      await _enter(tester, 'truing-range', '100');
      await _enter(
        tester,
        'truing-observed',
        observed.toStringAsFixed(4).replaceAll('.', ','),
      );
      await _tapKey(tester, 'truing-compute');
      expect(find.byKey(const Key('truing-error')), findsNothing);
      await _tapKey(tester, 'truing-bc-apply');
      await _tapKey(tester, 'truing-bc-confirm');

      final record = (await ManualCatalogStore().all()).singleWhere(
        (e) => e['id'] == 'manual_ammo_k10',
      );
      final bc = (record['bc'] as num).toDouble();
      // Solved at 255 m/s: the BC stays about 0,031 (it was about 0,025
      // when the truing solved at 270 m/s).
      expect(bc, closeTo(0.031, 0.001));
      expect(
        _correction(_k10Profile.muzzleVelocityMps, bc, 100),
        closeTo(observed, 0.05),
      );
    });
  });
}
