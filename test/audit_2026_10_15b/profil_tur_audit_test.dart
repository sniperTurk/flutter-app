// Pre-TestFlight audit 2026-10-15b — Profil (#318 Seçiniz defaults, #323
// Tür required for a new profile).
//
// PRF-7 (orta): picking Tür after the form is filled resets the chosen
//   cartridge even when the Tür did not change (profile_editor.dart, Tür
//   onChanged: `_cartridge = null` runs for `changed == false`). A
//   .300 Win Mag then shows as .308 Win (first 7,82 mm cartridge) and the
//   Fabrika fişeği list widens to every 7,82 mm round.
// PRF-8 (düşük): same handler; an El dolumu bullet whose diameter is not
//   in the Kalibre list (Hornady .321, 8,15 mm) loses its Kalibre when Tür
//   is picked, and 8,15 mm cannot be picked again.
// Guard (no finding): Profili Düzenle → Güncelle on an old profile whose
//   saved values are not in today's lists keeps every saved number.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import '../support/rifle_form.dart';

Future<MemoryProfileStore> _pumpList(
  WidgetTester tester, {
  RifleProfile? saved,
}) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  if (saved != null) await store.save(saved);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> _newProfile(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  expect(find.text('Profil Oluştur'), findsOneWidget);
}

String _missingText(WidgetTester tester) {
  final f = find.byKey(const Key('profile-missing'));
  return f.evaluate().isEmpty ? '' : tester.widget<Text>(f).data!;
}

// An old firearm profile whose round and scope are typed records that no
// list of today offers (saved before #318).
const _oldRifle = <String, dynamic>{
  'id': 'manual_rifle_d15b_old',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Eski Tüfek',
  'model': 'Özel',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 11,
};
const _oldAmmo = <String, dynamic>{
  'id': 'manual_ammo_d15b_old',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Eski Marka',
  'model': 'Eski Fişek',
  'caliberMm': 7.82,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.475,
  'bcModel': 'g1',
};
const _oldScope = <String, dynamic>{
  'id': 'manual_scope_d15b_old',
  'kind': 'scope',
  'platform': 'firearm',
  'brand': 'Eski Optik',
  'model': '4-16x44 SFP',
  'objectiveMm': 44,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'sfp',
  'minMag': 4,
  'maxMag': 16,
  'magnification': '4-16x',
};
final RifleProfile _oldProfile = const ProfileCodec().decode({
  'id': 'd15b-old',
  'name': 'Eski Profil',
  'rifleId': 'manual_rifle_d15b_old',
  'ammunitionId': 'manual_ammo_d15b_old',
  'scopeId': 'manual_scope_d15b_old',
  'muzzleVelocityMps': 812.5,
  'zeroRangeM': 100.0,
  'sightHeightMm': 47.0,
  'angularUnit': 'mrad',
  'distanceUnit': 'meter',
  'mountCantMoa': 0.0,
});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('PRF-7: picking Tür (unchanged) keeps the chosen .300 Win Mag',
      (tester) async {
    await _pumpList(tester);
    await _newProfile(tester);
    await openRifleManual(tester);
    await enterRifleField(tester, 'rifle-brand', 'Test Marka');
    await enterRifleField(tester, 'rifle-model', 'Test Model');
    await chooseInSelect(tester, 'rifle-caliber', '.300 Win Mag');
    expect(selectedValue<String>(tester, 'rifle-caliber'), '.300 Win Mag');
    await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
    expect(
      selectedValue<String>(tester, 'rifle-caliber'),
      '.300 Win Mag',
      reason: 'Tür pick replaced the cartridge',
    );
  }, skip: 'PRF-7 (orta, açık): Tür seçimi Kalibre fişeğini sıfırlıyor');

  testWidgets('PRF-8: El dolumu .321 bullet keeps its Kalibre when Tür is '
      'picked', (tester) async {
    await _pumpList(tester);
    await _newProfile(tester);
    await chooseInSelect(tester, 'ammo-source', 'El dolumu');
    await chooseInSelect(tester, 'ammo-brand-select', 'Hornady');
    await chooseInSelect(
      tester,
      'ammo-model-select',
      '.321 170 gr InterLock FP',
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('rifle-caliber')),
        matching: find.textContaining('8.15'),
      ),
      findsWidgets,
      reason: 'precondition: the bullet set Kalibre 8,15 mm',
    );
    await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
    expect(
      find.descendant(
        of: find.byKey(const Key('rifle-caliber')),
        matching: find.textContaining('8.15'),
      ),
      findsWidgets,
      reason: 'Tür pick emptied Kalibre',
    );
  }, skip: false);

  testWidgets('old profile with values outside today\'s lists: Güncelle '
      'keeps every saved number', (tester) async {
    final entries = [_oldRifle, _oldAmmo, _oldScope];
    SharedPreferences.setMockInitialValues({
      ManualCatalogStore.key: jsonEncode(entries),
    });
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([
        for (final e in entries) {...e},
      ]),
    );
    final store = await _pumpList(tester, saved: _oldProfile);
    final row = find.text('Eski Profil').first;
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Profili Düzenle'), findsOneWidget);
    expect(_missingText(tester), isEmpty);
    final update = find.widgetWithText(MenzilPrimaryButton, 'Güncelle');
    await tester.ensureVisible(update);
    await tester.tap(update);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final p = (await store.all()).single;
    expect(p.muzzleVelocityMps, closeTo(812.5, 0.01));
    expect(p.zeroRangeM, closeTo(100, 1e-9));
    expect(p.sightHeightMm, closeTo(47, 1e-9));
    expect(p.angularUnit, AngularUnit.mrad);
    expect(p.distanceUnit, DistanceUnit.meter);
    final ammo = CatalogRepository.allAmmunition.singleWhere(
      (a) => a.id == p.ammunitionId,
    );
    expect(ammo.ballisticCoefficient, closeTo(0.475, 1e-12));
    expect(ammo.ballisticModel, BallisticModel.g1);
    expect(ammo.grain, closeTo(175, 1e-9));
    expect(ammo.caliberMm, closeTo(7.82, 1e-9));
    final rifle = CatalogRepository.allRifles.singleWhere(
      (r) => r.id == p.rifleId,
    );
    expect(rifle.platform, WeaponPlatform.firearm);
    expect(rifle.twistRateIn, closeTo(11, 1e-9));
  });
}
