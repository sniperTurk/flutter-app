// Tür zorunlu (owner, 2026-10-15 14:25: "sorunu çöz, bu çok basit bir şey").
// A new profile's Tür box starts on "Seçiniz" (#318). Like every other
// required list box (Mesafe birimi, Dürbün birimi, Dürbün ayağı, Mühimmat
// türü) it now blocks saving and is named first in "Kaydetmek için eksik"
// ("Tüfek: Tür, Marka, …"); before, the profile was silently saved as a
// firearm profile. Profili Düzenle is unchanged: the saved Tür is filled in.
// Report: docs/reports/tur_zorunlu.md.
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

import 'support/rifle_form.dart';

// ---- Saved data (as the app stores it) ----

const _pcpRifle = <String, dynamic>{
  'id': 'manual_rifle_tur_pcp',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Atölye',
  'model': 'Slug',
  'caliberMm': 6.35,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 17,
  'regulatorBar': 120,
  'sourceName': 'Kullanıcı girdisi',
};
const _pcpAmmo = <String, dynamic>{
  'id': 'manual_ammo_tur_pcp',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Kendi',
  'model': '',
  'caliberMm': 6.35,
  'grain': 33.95,
  'ammoType': 'slug',
  'bc': 0.1,
  'bcModel': 'g1',
  'sourceName': 'Kullanıcı girdisi',
};
const _pcpScope = <String, dynamic>{
  'id': 'manual_scope_tur_pcp',
  'kind': 'scope',
  'platform': 'pcp',
  'brand': 'Optik',
  'model': '4-16x44',
  'objectiveMm': 44,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'sfp',
  'minMag': 4,
  'maxMag': 16,
};
const _pcpProfile = RifleProfile(
  id: 'tur-pcp',
  name: 'PCP Profil',
  rifleId: 'manual_rifle_tur_pcp',
  ammunitionId: 'manual_ammo_tur_pcp',
  scopeId: 'manual_scope_tur_pcp',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 55,
  pressureBar: 190,
);

const _fireRifle = <String, dynamic>{
  'id': 'manual_rifle_tur_fire',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'TIKKA',
  'model': 'T3X Tact A1',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 11,
};
const _fireAmmo = <String, dynamic>{
  'id': 'manual_ammo_tur_fire',
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
const _fireScope = <String, dynamic>{
  'id': 'manual_scope_tur_fire',
  'kind': 'scope',
  'platform': 'firearm',
  'brand': 'Atölyem Optik',
  'model': '4-16x44 SFP',
  'objectiveMm': 44,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'sfp',
  'minMag': 4,
  'maxMag': 16,
  'magnification': '4-16x',
};
final RifleProfile _fireProfile = const ProfileCodec().decode({
  'id': 'tur-fire',
  'name': 'Ateşli Profil',
  'rifleId': 'manual_rifle_tur_fire',
  'ammunitionId': 'manual_ammo_tur_fire',
  'scopeId': 'manual_scope_tur_fire',
  'muzzleVelocityMps': 800.0,
  'zeroRangeM': 100.0,
  'sightHeightMm': 45.0,
  'angularUnit': 'mrad',
  'distanceUnit': 'meter',
  'mountCantMoa': 0.0,
});

void _installSaved(List<Map<String, dynamic>> entries) {
  SharedPreferences.setMockInitialValues({
    ManualCatalogStore.key: jsonEncode(entries),
  });
  CatalogRepository.installUserCatalog(
    UserCatalog.fromManualEntries([
      for (final e in entries) {...e},
    ]),
  );
}

// ---- Pumping ----

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

Future<void> _openEdit(WidgetTester tester, String name) async {
  final row = find.text(name).first;
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.text('Profili Düzenle'), findsOneWidget);
}

String _missingText(WidgetTester tester) {
  final f = find.byKey(const Key('profile-missing'));
  return f.evaluate().isEmpty ? '' : tester.widget<Text>(f).data!;
}

/// The names listed under "Tüfek:" in "Kaydetmek için eksik".
List<String> _rifleMissing(WidgetTester tester) {
  final text = _missingText(tester);
  if (text.isEmpty) return const [];
  final body = text.substring('Kaydetmek için eksik: '.length);
  for (final part in body.split(' · ')) {
    if (part.startsWith('Tüfek: ')) {
      return part.substring('Tüfek: '.length).split(', ');
    }
  }
  return const [];
}

MenzilPrimaryButton _button(WidgetTester tester, String label) =>
    tester.widget<MenzilPrimaryButton>(
      find.widgetWithText(MenzilPrimaryButton, label),
    );

WeaponPlatform? _tur(WidgetTester tester) =>
    selectedValue<WeaponPlatform>(tester, 'profile-platform');

/// Every box of a new firearm profile except Tür (left on "Seçiniz").
Future<void> _fillAllButTur(WidgetTester tester) async {
  // Tüfek by hand: fillRifleForm would pick the Tür too.
  await openRifleManual(tester);
  await enterRifleField(tester, 'rifle-brand', 'Test Marka');
  await enterRifleField(tester, 'rifle-model', 'Test Model');
  await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
  await enterRifleField(tester, 'rifle-twist-rate', '11');
  await chooseTwistDirection(tester, 'Sağ');
  await fillScopeForm(tester);
  await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
  await openAmmoManual(tester);
  await chooseInSelect(tester, 'ammo-brand-pick', 'Diğer');
  await enterRifleField(tester, 'ammo-brand', 'Atölye Fişek');
  await enterRifleField(tester, 'ammo-model', 'Özel 1');
  await chooseInSelect(tester, 'ammo-grain-select', 'Listede yok');
  await enterRifleField(tester, 'ammo-grain', '173');
  await enterRifleField(tester, 'ammo-bc', '0,5');
  await chooseInSelect(tester, 'ammo-bc-model', 'G7');
  await chooseInSelect(tester, 'profile-powder-coef', '1,5');
  await chooseInSelect(tester, 'profile-powder-temp', '21');
  await fillShotValues(tester, velocityFps: '2650', zero: '100', sight: '45');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('new profile: Tür on "Seçiniz" is listed first and blocks '
      'Kaydet', (tester) async {
    await _pumpList(tester);
    await tester.tap(find.byTooltip('Yeni profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Oluştur'), findsOneWidget);
    expect(_tur(tester), isNull);
    expect(_rifleMissing(tester).first, 'Tür');
    expect(_button(tester, 'Kaydet').onPressed, isNull);
  });

  testWidgets('new profile: everything else filled, Tür alone blocks; '
      'picking it removes "Tür" and saves', (tester) async {
    final store = await _pumpList(tester);
    await tester.tap(find.byTooltip('Yeni profil'));
    await tester.pumpAndSettle();
    await _fillAllButTur(tester);

    // Only Tür is missing, and saving is blocked.
    expect(_tur(tester), isNull);
    expect(_missingText(tester), 'Kaydetmek için eksik: Tüfek: Tür');
    expect(_button(tester, 'Kaydet').onPressed, isNull);
    final save = find.widgetWithText(MenzilPrimaryButton, 'Kaydet');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(await store.all(), isEmpty);
    expect(find.text('Profil Oluştur'), findsOneWidget);

    // Picking Tür removes the entry; nothing else is cleared.
    await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
    expect(_tur(tester), WeaponPlatform.firearm);
    expect(_rifleMissing(tester), isNot(contains('Tür')));
    expect(_missingText(tester), isEmpty);
    expect(_button(tester, 'Kaydet').onPressed, isNotNull);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final saved = (await store.all()).single;
    final rifle = CatalogRepository.allRifles.singleWhere(
      (r) => r.id == saved.rifleId,
    );
    expect(rifle.platform, WeaponPlatform.firearm);
  });

  testWidgets('new profile: picking PCP Tüfek also removes "Tür"', (
    tester,
  ) async {
    await _pumpList(tester);
    await tester.tap(find.byTooltip('Yeni profil'));
    await tester.pumpAndSettle();
    expect(_rifleMissing(tester), contains('Tür'));
    await chooseInSelect(tester, 'profile-platform', 'PCP Tüfek');
    expect(_tur(tester), WeaponPlatform.pcp);
    expect(_rifleMissing(tester), isNot(contains('Tür')));
  });

  for (final (label, entries, profile, platform) in [
    (
      'PCP',
      const [_pcpRifle, _pcpAmmo, _pcpScope],
      _pcpProfile,
      WeaponPlatform.pcp,
    ),
    (
      'firearm',
      const [_fireRifle, _fireAmmo, _fireScope],
      _fireProfile,
      WeaponPlatform.firearm,
    ),
  ]) {
    testWidgets('existing $label profile: Tür filled in, Güncelle works, '
        'platform kept after save -> reopen', (tester) async {
      _installSaved(entries);
      final store = await _pumpList(tester, saved: profile);
      await _openEdit(tester, profile.name);
      expect(_tur(tester), platform);
      expect(_rifleMissing(tester), isNot(contains('Tür')));
      expect(_button(tester, 'Güncelle').onPressed, isNotNull);

      final update = find.widgetWithText(MenzilPrimaryButton, 'Güncelle');
      await tester.ensureVisible(update);
      await tester.tap(update);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Profili Düzenle'), findsNothing);
      final saved = (await store.all()).single;
      final rifle = CatalogRepository.allRifles.singleWhere(
        (r) => r.id == saved.rifleId,
      );
      expect(rifle.platform, platform);

      await _openEdit(tester, saved.name);
      expect(_tur(tester), platform);
      expect(_rifleMissing(tester), isNot(contains('Tür')));
      expect(_button(tester, 'Güncelle').onPressed, isNotNull);
    });
  }
}
