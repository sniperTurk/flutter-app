// BC'siz fabrika fişeği (owner, 2026-10-14 15:16 / 15:18): a listed factory
// load whose maker publishes no BC stays empty ("kullanıcı bu fişeği seçerse
// BC'yi kendisi girer") and its BC ⓘ says so, as a BC-less listed bullet
// already does ("Ekle, iyi olur."). Report: docs/reports/fisek_bc_yok_notu.md.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/bullet_library.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profile_field_info.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

const _fisekNote =
    "\n\nBu fişek: Üretici BC yayımlamıyor. Kendi atışlarınızdan bulduğunuz "
    "BC'yi girin; BC modelini de seçin.";
const _mermiNote =
    "\n\nBu mermi: Üretici BC yayımlamıyor. Kendi atışlarınızdan bulduğunuz "
    "BC'yi girin.";

Future<void> _openNew(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
}

Future<void> _pickBlackHills223(WidgetTester tester, String model) async {
  await chooseInSelect(tester, 'rifle-caliber', '.223 Rem');
  await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
  await chooseInSelect(tester, 'ammo-brand-select', 'Black Hills');
  await chooseInSelect(tester, 'ammo-model-select', model);
}

String _bcInfo(WidgetTester tester) =>
    tester.widget<MenzilInput>(find.byKey(const Key('ammo-bc'))).info!;

String _bcText(WidgetTester tester) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('ammo-bc')),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

/// The Mühimmat part of "Kaydetmek için eksik: …", split into labels.
List<String> _missingAmmo(WidgetTester tester) {
  final f = find.byKey(const Key('profile-missing'));
  if (f.evaluate().isEmpty) return const [];
  final text = tester.widget<Text>(f).data!;
  for (final part in text.split(' · ')) {
    final i = part.indexOf('Mühimmat: ');
    if (i >= 0) return part.substring(i + 'Mühimmat: '.length).split(', ');
  }
  return const [];
}

FactoryAmmo _load(String name) => FactoryAmmoLibrary.all.singleWhere(
  (a) => a.brand == 'Black Hills' && a.name == name,
);

// A saved PCP profile with a listed, BC-less pellet (Spoton Match): the
// bullet / pellet branch of the BC ⓘ (PCP Marka | Model are hidden, so a
// saved record is how the editor gets one).
const _rifle = <String, dynamic>{
  'id': 'manual_rifle_pellet',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Atölye',
  'model': 'Pellet',
  'caliberMm': 4.5,
  'barrelLengthMm': 500,
  'twistDirection': 'right',
  'twistRateIn': 16,
  'regulatorBar': 120,
  'sourceName': 'Kullanıcı girdisi',
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_pellet',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Spoton',
  'model': 'Match',
  'caliberMm': 4.5,
  'grain': 9.25,
  'ammoType': 'pellet',
  'bc': 0.02,
  'bcModel': 'g1',
  'sourceName': 'Kullanıcı girdisi',
};
const _scope = <String, dynamic>{
  'id': 'manual_scope_pellet',
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
  id: 'pellet',
  name: 'Pellet Profil',
  rifleId: 'manual_rifle_pellet',
  ammunitionId: 'manual_ammo_pellet',
  scopeId: 'manual_scope_pellet',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 50,
  pressureBar: 190,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  test('the library fixtures: one BC-less, one with BC', () {
    expect(_load('Black Hills 52 gr Match HP').bc, isNull);
    expect(_load('Black Hills 52 gr Match HP').note, isNull);
    expect(_load('Black Hills 50 gr Hornady V-MAX').bc, isNotNull);
    final match = BulletLibrary.all.singleWhere(
      (b) => b.brand == 'Spoton' && b.name == 'Match',
    );
    expect(match.bc, isNull);
    expect(match.platform, WeaponPlatform.pcp);
  });

  testWidgets('BC-less factory load: the BC ⓘ says so, the box stays empty', (
    tester,
  ) async {
    await _openNew(tester);
    await _pickBlackHills223(tester, 'Black Hills 52 gr Match HP');
    expect(_bcText(tester), '');
    expect(_bcInfo(tester), '${ProfileFieldInfo.bcFirearm}$_fisekNote');
    expect(_bcInfo(tester), isNot(contains('Bu mermi:')));
    // ⓘ only: no helper text under the box.
    expect(find.textContaining('Üretici BC yayımlamıyor'), findsNothing);
  });

  testWidgets('factory load with a BC: no new sentence, note as before', (
    tester,
  ) async {
    await _openNew(tester);
    await _pickBlackHills223(tester, 'Black Hills 50 gr Hornady V-MAX');
    final a = _load('Black Hills 50 gr Hornady V-MAX');
    expect(
      _bcInfo(tester),
      '${ProfileFieldInfo.bcFirearm}\n\nBu fişek: ${a.note}',
    );
    expect(_bcInfo(tester), isNot(contains('Üretici BC yayımlamıyor')));
  });

  testWidgets('BC stays required: save blocked until a BC is typed', (
    tester,
  ) async {
    await _openNew(tester);
    await _pickBlackHills223(tester, 'Black Hills 52 gr Match HP');
    expect(_missingAmmo(tester), contains('BC'));
    expect(
      tester
          .widget<MenzilPrimaryButton>(
            find.widgetWithText(MenzilPrimaryButton, 'Kaydet'),
          )
          .onPressed,
      isNull,
    );
    await enterRifleField(tester, 'ammo-bc', '0,3');
    expect(_missingAmmo(tester), isNot(contains('BC')));
    // The ⓘ keeps the note after a BC is typed.
    expect(_bcInfo(tester), endsWith(_fisekNote));
  });

  testWidgets('BC-less listed pellet: the old "Bu mermi" sentence unchanged', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ManualCatalogStore.key: jsonEncode([_rifle, _ammo, _scope]),
    });
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo, _scope]),
    );
    tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = MemoryProfileStore();
    await store.save(_pcpProfile);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: ProfilesScreen(store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_pcpProfile.name).first);
    await tester.pumpAndSettle();
    expect(_bcInfo(tester), '${ProfileFieldInfo.bc}$_mermiNote');
    expect(_bcInfo(tester), isNot(contains('Bu fişek:')));
  });
}
