// Pre-TestFlight audit 2026-10-15b — Hedef numbers end to end after the
// behaviour-neutral moves #317 (Hedef/Hava/Pro part files), #318 (Profil
// part files) and #324 (formulas moved to lib/core).
//
// Saved record → profile → Hedef DOPE number, compared with the hand
// calculation in tools/denetim_2026_10_15b.py (independent reference solver
// tools/formula_reference.py: published G1/G7 tables, CIPM-2007 air; no
// other ballistic app). Also the yard (inch-system) path. The same file
// runs unchanged on the previous TestFlight (d86dfff) as a before/after check.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_codec.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_d15b',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};

const _ammoG1 = <String, dynamic>{
  'id': 'manual_ammo_d15b_g1',
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

const _ammoG7 = <String, dynamic>{
  'id': 'manual_ammo_d15b_g7',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test 175',
  'model': '',
  'caliberMm': 7.62,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.243,
  'bcModel': 'g7',
};

/// python3 tools/denetim_2026_10_15b.py (300 / 600 / 1000, mrad).
const _handA = [1.6287, 5.5308, 14.1368]; // G1, metres
const _handB = [1.6597, 5.5714, 14.3291]; // G7, metres
const _handC = [1.4286, 4.8141, 12.0019]; // G7, yards (zero 100 yd)
const _ranges = [300.0, 600.0, 1000.0];

RifleProfile _decode(Map<String, dynamic> extra) =>
    const ProfileCodec().decode({
      'rifleId': 'manual_rifle_d15b',
      'scopeId': 'gazi-6-36',
      'sightHeightMm': 45.0,
      'angularUnit': 'mrad',
      'distanceUnit': 'meter',
      'mountCantMoa': 0.0,
      ...extra,
    });

Future<void> _seed() async {
  SharedPreferences.setMockInitialValues({});
  for (final e in [_rifle, _ammoG1, _ammoG7]) {
    await ManualCatalogStore().upsert(e);
  }
  CatalogRepository.installUserCatalog(
    UserCatalog.fromManualEntries(await ManualCatalogStore().all()),
  );
}

Finder _field(Key key) => find
    .descendant(
      of: find.byKey(key),
      matching: find.byType(TextField),
      matchRoot: true,
    )
    .first;

Future<void> _enter(WidgetTester tester, Key key, String text) async {
  final f = _field(key);
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump();
}

/// Hedef → DOPE for [ranges] (in the profile's distance unit) at 15 °C,
/// 1013,25 hPa, %50; returns the "Yükseklik MRAD" column per range.
Future<List<double>> _dope(
  WidgetTester tester,
  RifleProfile p,
  List<double> ranges,
) async {
  tester.view.physicalSize = const Size(1000, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(MaterialApp(home: BallisticsScreen(profile: p)));
  await tester.pumpAndSettle();
  await _enter(tester, BallisticsFieldKeys.temperature, '15');
  await _enter(tester, BallisticsFieldKeys.pressure, '1013,25');
  await _enter(tester, BallisticsFieldKeys.humidity, '50');
  await _enter(
    tester,
    BallisticsFieldKeys.ranges,
    ranges.map((r) => r.toStringAsFixed(0)).join(' '),
  );
  final dope = find.text('DOPE oluştur').first;
  await tester.ensureVisible(dope);
  await tester.tap(dope);
  await tester.pumpAndSettle();
  final table = tester.widget<DataTable>(find.byType(DataTable).first);
  final col = table.columns.indexWhere(
    (c) => c.label is Text && (c.label as Text).data == 'Yükseklik MRAD',
  );
  expect(col, isNonNegative, reason: 'DOPE has no MRAD column');
  double cell(DataRow r, int i) =>
      double.parse((r.cells[i].child as Text).data!.replaceAll(',', '.'));
  return [
    for (final r in ranges)
      cell(table.rows.firstWhere((row) => (cell(row, 0) - r).abs() < 0.5), col),
  ];
}

void _expectHand(List<double> shown, List<double> hand) {
  for (var i = 0; i < hand.length; i++) {
    expect(
      shown[i],
      closeTo(hand[i], 0.02),
      reason: '${_ranges[i]}: app ${shown[i]} vs hand ${hand[i]}',
    );
  }
}

void main() {
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('A: G1 metre profile, Hedef DOPE = hand calculation', (
    tester,
  ) async {
    await _seed();
    final p = _decode({
      'id': 'd15b-a',
      'name': 'A',
      'ammunitionId': 'manual_ammo_d15b_g1',
      'muzzleVelocityMps': 800.0,
      'zeroRangeM': 100.0,
    });
    _expectHand(await _dope(tester, p, _ranges), _handA);
  });

  testWidgets('B: G7 metre profile, Hedef DOPE = hand calculation', (
    tester,
  ) async {
    await _seed();
    final p = _decode({
      'id': 'd15b-b',
      'name': 'B',
      'ammunitionId': 'manual_ammo_d15b_g7',
      'muzzleVelocityMps': 790.0,
      'zeroRangeM': 100.0,
    });
    _expectHand(await _dope(tester, p, _ranges), _handB);
  });

  testWidgets('C: G7 yard profile (zero 100 yd), DOPE in yards = hand '
      'calculation', (tester) async {
    await _seed();
    final p = _decode({
      'id': 'd15b-c',
      'name': 'C',
      'ammunitionId': 'manual_ammo_d15b_g7',
      'muzzleVelocityMps': 790.0,
      'zeroRangeM': 91.44,
      'distanceUnit': 'yard',
    });
    _expectHand(await _dope(tester, p, _ranges), _handC);
  });
}
