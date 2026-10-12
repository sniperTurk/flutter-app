// Ö7 Avcı Sıfırı page: zone list, suggestion only (the profile is never
// written), PCP and firearm, yard profile.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/tools/mpbr_screen.dart';
import 'package:sniper_turk/features/tools/tools_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_mp',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_mp',
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
const _pellet = <String, dynamic>{
  'id': 'c-mp',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'Deneme',
  'model': '.22 pellet',
  'caliberMm': 5.5,
  'grain': 18,
  'ammoType': 'pellet',
  'bc': 0.031,
  'bcModel': 'G1',
};

const _t1 = RifleProfile(
  id: 'p-t1',
  name: 'T1',
  rifleId: 'manual_rifle_mp',
  ammunitionId: 'manual_ammo_mp',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 790,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

const _p1 = RifleProfile(
  id: 'p-p1',
  name: 'P1',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-mp',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 275,
  zeroRangeM: 30,
  sightHeightMm: 50,
);

Future<MemoryProfileStore> _pump(WidgetTester tester, RifleProfile? p) async {
  tester.view.physicalSize = const Size(430, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  final active = MemoryActiveProfileStore();
  if (p != null) {
    await store.save(p);
    active.value = p.id;
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: MpbrScreen(profileStore: store, activeProfileStore: active),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> _pickZone(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('mpbr-zone')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

String _line(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('mpbr-line'))).data!;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo, _pellet]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('no active profile: says so', (tester) async {
    await _pump(tester, null);
    expect(find.byKey(const Key('mpbr-no-profile')), findsOneWidget);
    expect(find.byKey(const Key('mpbr-zone')), findsNothing);
  });

  testWidgets('zone list starts at Seçiniz, has ⓘ, nothing computed yet', (
    tester,
  ) async {
    await _pump(tester, _t1);
    expect(find.text('Seçiniz'), findsOneWidget);
    expect(find.byTooltip('Bilgi: Hedef bölge çapı'), findsOneWidget);
    expect(find.byKey(const Key('mpbr-line')), findsNothing);
    await tester.tap(find.byKey(const Key('mpbr-zone')));
    await tester.pumpAndSettle();
    for (final l in ['2,5 cm', '4 cm', '10 cm', '15 cm', '20 cm']) {
      expect(find.text(l), findsWidgets, reason: l);
    }
  });

  testWidgets('T1 15 cm: zero ≈ 203 m, profile untouched', (tester) async {
    final store = await _pump(tester, _t1);
    await _pickZone(tester, '15 cm');
    final line = _line(tester);
    expect(line, startsWith('Sıfır 2'));
    expect(line, contains('arası tutuşsuz'));
    expect(
      find.descendant(
        of: find.byKey(const Key('mpbr-profile-zero')),
        matching: find.textContaining('100 m'),
      ),
      findsOneWidget,
    );
    final saved = (await store.all()).single;
    expect(saved.zeroRangeM, 100);
  });

  testWidgets('PCP pellet 2,5 cm: result within 50 m', (tester) async {
    await _pump(tester, _p1);
    await _pickZone(tester, '2,5 cm');
    expect(_line(tester), matches(RegExp(r'^Sıfır [34]\d m: 1\d–4\d m arası')));
  });

  testWidgets('yard profile: result in yards', (tester) async {
    await _pump(
      tester,
      const RifleProfile(
        id: 'p-t1y',
        name: 'T1y',
        rifleId: 'manual_rifle_mp',
        ammunitionId: 'manual_ammo_mp',
        scopeId: 'gazi-6-36',
        muzzleVelocityMps: 790,
        zeroRangeM: 100,
        sightHeightMm: 45,
        distanceUnit: DistanceUnit.yard,
      ),
    );
    await _pickZone(tester, '15 cm');
    expect(_line(tester), contains(' yd'));
  });

  testWidgets('hub lists Avcı Sıfırı for both platforms', (tester) async {
    for (final p in [WeaponPlatform.pcp, WeaponPlatform.firearm, null]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: Scaffold(body: ToolsScreen(activePlatform: p)),
        ),
      );
      expect(find.byKey(const Key('tool-mpbr')), findsOneWidget);
    }
  });
}
