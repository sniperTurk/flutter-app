// Profili Düzenle (owner, 2026-10-13): the Kimlik "Üretim" box shows the
// origin of the saved rifle instead of "Seçiniz", and the rifle stays chosen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/rifle_form.dart';

const _imported = Rifle(
  id: 'user-christensen-mpr-rimfire',
  brand: 'Christensen Arms',
  model: 'Modern Precision Rifle Rimfire',
  platform: WeaponPlatform.firearm,
  caliberMm: 4.37,
  userEntered: true,
);

const _domesticRifle = Rifle(
  id: 'user-hatsan-escort-22lr',
  brand: 'Hatsan',
  model: 'Escort 22LR',
  platform: WeaponPlatform.firearm,
  caliberMm: 5.69,
  userEntered: true,
);

const _typed = Rifle(
  id: 'user-typed-rifle',
  brand: 'Atölyem',
  model: 'Özel Yapım',
  platform: WeaponPlatform.firearm,
  caliberMm: 7.82,
  userEntered: true,
);

RifleProfile _profile(Rifle r) => RifleProfile(
  id: 'p-${r.id}',
  name: 'Profil ${r.model}',
  rifleId: r.id,
  ammunitionId: 'removed-ammo-id',
  scopeId: 'removed-scope-id',
  muzzleVelocityMps: 380,
  zeroRangeM: 50,
  sightHeightMm: 50,
);

Future<void> _openEdit(WidgetTester tester, Rifle rifle) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  final profile = _profile(rifle);
  await store.save(profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(profile.name).first);
  await tester.pumpAndSettle();
  expect(find.text('Profili Düzenle'), findsOneWidget);
}

Finder _in(String key, Finder f) =>
    find.descendant(of: find.byKey(Key(key)), matching: f);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      const UserCatalog(rifles: [_imported, _domesticRifle, _typed]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('an imported library rifle opens on Üretim İthal', (
    tester,
  ) async {
    await _openEdit(tester, _imported);
    expect(selectedValue<bool?>(tester, 'rifle-origin'), isFalse);
    expect(_in('rifle-origin', find.text('İthal')), findsOneWidget);
    expect(_in('rifle-origin', find.text('Seçiniz')), findsNothing);
    // Marka and Model keep the saved rifle; it is not a typed rifle.
    expect(
      selectedValue<String>(tester, 'rifle-brand-select'),
      'Christensen Arms',
    );
    expect(
      selectedValue<String>(tester, 'rifle-model-select'),
      'Modern Precision Rifle Rimfire',
    );
    expect(find.byKey(const Key('rifle-brand')), findsNothing);
  });

  testWidgets('a domestic library rifle (Hatsan) opens on Üretim Yerli', (
    tester,
  ) async {
    await _openEdit(tester, _domesticRifle);
    expect(selectedValue<bool?>(tester, 'rifle-origin'), isTrue);
    expect(_in('rifle-origin', find.text('Yerli')), findsOneWidget);
    expect(selectedValue<String>(tester, 'rifle-brand-select'), 'Hatsan');
    expect(selectedValue<String>(tester, 'rifle-model-select'), 'Escort 22LR');
    expect(find.byKey(const Key('rifle-brand')), findsNothing);
  });

  testWidgets('a typed ("Listede yok") rifle leaves Üretim on Seçiniz', (
    tester,
  ) async {
    await _openEdit(tester, _typed);
    expect(selectedValue<bool?>(tester, 'rifle-origin'), isNull);
    // The typed boxes keep the saved values.
    String text(String key) => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(TextField),
          ),
        )
        .controller!
        .text;
    expect(text('rifle-brand'), 'Atölyem');
    expect(text('rifle-model'), 'Özel Yapım');
  });
}
