// Owner, 2026-10-13 23:32 ("Profilden çıkartın") hid the Profil length;
// owner, 2026-10-17 11:34 ("al bunu oraya") moved it back: Profil >
// Mühimmat > Mermi uzunluğu (firearm and PCP), the hiding flag deleted. The
// summary still shows no Uzunluk line, and a length saved before is shown
// and kept, never lost. Report: docs/reports/pro_barut_not.md.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_len',
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

/// Saved before the box was hidden: carries a length.
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_len',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Kendi',
  'model': '',
  'caliberMm': 6.35,
  'grain': 33.95,
  'ammoType': 'slug',
  'bc': 0.1,
  'bcModel': 'g1',
  'lengthMm': 10.5,
  'sourceName': 'Kullanıcı girdisi',
};
const _scope = <String, dynamic>{
  'id': 'manual_scope_len',
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

const _profile = RifleProfile(
  id: 'old-len',
  name: 'Eski Slug',
  rifleId: 'manual_rifle_len',
  ammunitionId: 'manual_ammo_len',
  scopeId: 'manual_scope_len',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 55,
  pressureBar: 190,
);

Future<MemoryProfileStore> _pump(
  WidgetTester tester, {
  String? activeProfileId,
}) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(_profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store, activeProfileId: activeProfileId),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      ManualCatalogStore.key: jsonEncode([_rifle, _ammo, _scope]),
    });
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo, _scope]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('the Profil summary shows no Uzunluk line', (tester) async {
    await _pump(tester, activeProfileId: _profile.id);
    final card = find.byKey(const Key('profile-summary-ammo'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('Ağırlık')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Uzunluk')),
      findsNothing,
    );
  });

  testWidgets('an old profile with a saved length opens with it in Mermi '
      'uzunluğu and keeps the length when saved', (tester) async {
    final store = await _pump(tester);
    await tester.tap(find.text(_profile.name).first);
    await tester.pumpAndSettle();
    expect(find.text('Profili Düzenle'), findsOneWidget);
    // PCP Mühimmat: the saved length in Mermi uzunluğu.
    final length = find.descendant(
      of: find.byKey(const Key('ammo-length')),
      matching: find.byType(TextField),
    );
    expect(length, findsOneWidget);
    expect(tester.widget<TextField>(length).controller!.text, '10.5');
    expect(find.byKey(const Key('ammo-grain')), findsOneWidget);
    final update = find.widgetWithText(MenzilPrimaryButton, 'Güncelle');
    expect(tester.widget<MenzilPrimaryButton>(update).onPressed, isNotNull);
    await tester.ensureVisible(update);
    await tester.tap(update);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The profile still points at an ammunition record that kept 10.5 mm.
    final saved = (await store.all()).single;
    final entries = await ManualCatalogStore().all();
    final ammo = entries.singleWhere((e) => e['id'] == saved.ammunitionId);
    expect(ammo['kind'], 'ammo');
    expect(ammo['lengthMm'], 10.5);
    expect(ammo['grain'], 33.95);
  });
}
