// Profil Oluştur/Düzenle, owner 2026-10-14: "Tüfek için aç, ateşli ve PCP
// olarak." The rifle Marka list has no "Listede yok" item any more (hidden
// behind RIFLE_LISTEDE_YOK, not deleted); the typed rifle entry opens from
// the link "Aradığın tüfek listede yok mu?" under Marka | Model, for Ateşli
// and PCP alike. Mühimmat and the scope form stay as they were.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

void _setView(WidgetTester tester) {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _openNew(
  WidgetTester tester, {
  required bool firearm,
  ProfileStore? store,
}) async {
  _setView(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store ?? MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  await chooseInSelect(
    tester,
    'profile-platform',
    firearm ? 'Ateşli Tüfek' : 'PCP Tüfek',
  );
}

Finder _key(String key) => find.byKey(Key(key));

Finder _in(String key, Finder f) => find.descendant(of: _key(key), matching: f);

String _text(WidgetTester tester, String key) =>
    tester.widget<TextField>(_in(key, find.byType(TextField))).controller!.text;

/// The labels of the list box under [key].
List<String?> _items(WidgetTester tester, String key) => [
  for (final i
      in tester
          .widget<MenzilSelect<String>>(
            _in(key, find.byType(MenzilSelect<String>)),
          )
          .items)
    i.child is Text ? (i.child as Text).data : null,
];

const _typedFirearm = Rifle(
  id: 'user-typed-firearm',
  brand: 'Atölyem',
  model: 'Özel Yapım',
  platform: WeaponPlatform.firearm,
  caliberMm: 7.82,
  userEntered: true,
);

const _typedPcp = Rifle(
  id: 'user-typed-pcp',
  brand: 'Atölyem',
  model: 'Özel PCP',
  platform: WeaponPlatform.pcp,
  caliberMm: 6.35,
  userEntered: true,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  for (final firearm in [true, false]) {
    final kind = firearm ? 'Ateşli' : 'PCP';

    testWidgets('$kind: no "Listede yok" item; the link is under Model', (
      tester,
    ) async {
      await _openNew(tester, firearm: firearm);
      final brands = _items(tester, 'rifle-brand-select');
      expect(brands, isNotEmpty);
      expect(brands, isNot(contains('Listede yok')));
      final link = _key('rifle-not-listed');
      expect(link, findsOneWidget);
      expect(
        _in('rifle-not-listed', find.text('Aradığın tüfek listede yok mu?')),
        findsOneWidget,
      );
      expect(tester.widget(link), isA<TextButton>());
      // Under the Marka | Model row, left-aligned inside the rifle card.
      final model = tester.getRect(_key('rifle-model-select'));
      final l = tester.getRect(link);
      expect(l.top, greaterThanOrEqualTo(model.bottom));
      expect(l.left, lessThan(model.center.dx));
      expect(
        find.descendant(of: _key('profile-rifle-form'), matching: link),
        findsOneWidget,
      );
      // The scope link is still there.
      expect(_key('scope-not-listed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$kind: the link opens empty typed Marka / Model', (
      tester,
    ) async {
      await _openNew(tester, firearm: firearm);
      await openRifleManual(tester);
      expect(_key('rifle-brand-select'), findsNothing);
      expect(_key('rifle-model-select'), findsNothing);
      expect(_text(tester, 'rifle-brand'), '');
      expect(_text(tester, 'rifle-model'), '');
      expect(_key('rifle-not-listed'), findsNothing);
      // Kalibre stays a list box.
      expect(_key('rifle-caliber'), findsOneWidget);
      // The way back to the lists brings the link back.
      await tester.ensureVisible(_key('rifle-back-to-list'));
      await tester.tap(_key('rifle-back-to-list'));
      await tester.pumpAndSettle();
      expect(_key('rifle-brand-select'), findsOneWidget);
      expect(_key('rifle-not-listed'), findsOneWidget);
    });

    testWidgets('$kind: a saved typed rifle reopens in typed mode', (
      tester,
    ) async {
      final rifle = firearm ? _typedFirearm : _typedPcp;
      CatalogRepository.installUserCatalog(UserCatalog(rifles: [rifle]));
      _setView(tester);
      final store = MemoryProfileStore();
      final profile = RifleProfile(
        id: 'p-${rifle.id}',
        name: 'Profil ${rifle.model}',
        rifleId: rifle.id,
        ammunitionId: 'removed-ammo-id',
        scopeId: 'removed-scope-id',
        muzzleVelocityMps: 300,
        zeroRangeM: 50,
        sightHeightMm: 50,
      );
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
      expect(_text(tester, 'rifle-brand'), 'Atölyem');
      expect(_text(tester, 'rifle-model'), rifle.model);
      expect(_key('rifle-brand-select'), findsNothing);
      expect(_key('rifle-not-listed'), findsNothing);
      expect(_key('rifle-back-to-list'), findsOneWidget);
    });
  }

  testWidgets('PCP: a listed rifle goes when the link is tapped', (
    tester,
  ) async {
    await _openNew(tester, firearm: false);
    await chooseInSelect(tester, 'rifle-brand-select', 'Hatsan');
    await chooseInSelect(tester, 'rifle-model-select', 'Hercules');
    await chooseInSelect(tester, 'rifle-caliber', '11.43 mm (.45)');
    expect(_in('rifle-caliber', find.text('11.43 mm (.45)')), findsOneWidget);
    await openRifleManual(tester);
    // As "Listede yok" did: Marka / Model empty, the listed caliber goes.
    expect(_text(tester, 'rifle-brand'), '');
    expect(_text(tester, 'rifle-model'), '');
    expect(_in('rifle-caliber', find.text('11.43 mm (.45)')), findsNothing);
    // A typed rifle keeps a caliber picked afterwards.
    await chooseInSelect(tester, 'rifle-caliber', '6.35 mm (.25)');
    await enterRifleField(tester, 'rifle-brand', 'Test Marka');
    expect(_in('rifle-caliber', find.text('6.35 mm (.25)')), findsOneWidget);
  });

  testWidgets('Ateşli: a listed rifle and its listed ammunition go', (
    tester,
  ) async {
    await _openNew(tester, firearm: true);
    await chooseInSelect(tester, 'rifle-brand-select', 'Tikka');
    await chooseInSelect(tester, 'rifle-model-select', 'T3x TACT A1');
    await chooseInSelect(
      tester,
      'rifle-caliber',
      '.308 Win · 20 in namlu · 1:11',
    );
    await chooseInSelect(tester, 'ammo-source', 'El dolumu');
    await chooseInSelect(tester, 'ammo-brand-select', 'Hornady');
    await tester.tap(find.byKey(const Key('ammo-model-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('168 gr ELD Match').last);
    await tester.pumpAndSettle();
    expect(_text(tester, 'ammo-grain'), '168');
    await openRifleManual(tester);
    expect(_text(tester, 'rifle-brand'), '');
    expect(_text(tester, 'rifle-model'), '');
    expect(
      _in('rifle-caliber', find.text('.308 Win · 20 in namlu · 1:11')),
      findsNothing,
    );
    // The listed ammunition of the cleared caliber goes, as before.
    expect(_text(tester, 'ammo-grain'), '');
  });

  // Owner, 2026-10-14 (fix/atesli-elle-muhimmat): the ammo "Listede yok"
  // item is hidden too; the typed round opens from its own link.
  testWidgets('Ateşli: Mühimmat Marka has the link, not "Listede yok"', (
    tester,
  ) async {
    await _openNew(tester, firearm: true);
    await openRifleManual(tester);
    await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
    if (find.byKey(const Key('ammo-source')).evaluate().isNotEmpty &&
        find.byKey(const Key('ammo-brand-select')).evaluate().isEmpty) {
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
    }
    expect(_items(tester, 'ammo-brand-select'), isNot(contains('Listede yok')));
    expect(_key('ammo-not-listed'), findsOneWidget);
  });

  testWidgets('PCP: a typed rifle saves and reopens in typed mode', (
    tester,
  ) async {
    final store = MemoryProfileStore();
    await _openNew(tester, firearm: false, store: store);
    await fillRifleForm(tester);
    await fillScopeForm(tester);
    await enterRifleField(tester, 'scope-travel-elevation', '170');
    await fillAmmoForm(tester);
    await fillShotValues(tester);
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Oluştur'), findsNothing);
    final saved = (await store.all()).single;
    await tester.tap(find.text(saved.name).first);
    await tester.pumpAndSettle();
    expect(find.text('Profili Düzenle'), findsOneWidget);
    expect(_text(tester, 'rifle-brand'), 'Test Marka');
    expect(_text(tester, 'rifle-model'), 'Test Model');
    expect(_key('rifle-brand-select'), findsNothing);
    expect(_key('rifle-not-listed'), findsNothing);
    expect(_in('rifle-caliber', find.text('6.35 mm (.25)')), findsOneWidget);
  });
}
