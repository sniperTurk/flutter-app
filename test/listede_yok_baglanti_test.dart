// Profil Oluştur / Düzenle, owner 2026-10-14: the rifle and the ammunition
// get what the scope got in #269. "Listede yok" is hidden in their Marka
// lists (RIFLE_LISTEDE_YOK / AMMO_LISTEDE_YOK, default off: "gizle, silme")
// and a link under Marka | Model opens the typed entry.
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

const _typedRifle = Rifle(
  id: 'user-typed-rifle-link',
  brand: 'Atölyem',
  model: 'Özel Yapım',
  platform: WeaponPlatform.firearm,
  caliberMm: 7.82,
  userEntered: true,
);

const _typedAmmo = Ammunition(
  id: 'user-typed-ammo-link',
  brand: 'Kendi Dolumum',
  model: 'Yarışma 175',
  platform: WeaponPlatform.firearm,
  caliberMm: 7.82,
  grain: 175,
  type: AmmunitionType.bullet,
  ballisticCoefficient: 0.505,
  ballisticModel: BallisticModel.g1,
  userEntered: true,
);

void _setView(WidgetTester tester) {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _openNew(WidgetTester tester, {required bool firearm}) async {
  _setView(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: MemoryProfileStore()),
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

Future<void> _openSaved(WidgetTester tester, RifleProfile profile) async {
  _setView(tester);
  final store = MemoryProfileStore();
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

List<String?> _items(WidgetTester tester, String key) => [
  for (final i
      in tester
          .widget<MenzilSelect<String>>(
            find.descendant(
              of: find.byKey(Key(key)),
              matching: find.byType(MenzilSelect<String>),
            ),
          )
          .items)
    if (i.child is Text) (i.child as Text).data,
];

String _text(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

Finder _key(String k) => find.byKey(Key(k));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final firearm in [true, false]) {
    final name = firearm ? 'Ateşli' : 'PCP';

    testWidgets('$name: rifle Marka has no "Listede yok"; the link types', (
      tester,
    ) async {
      await _openNew(tester, firearm: firearm);
      final items = _items(tester, 'rifle-brand-select');
      expect(items, isNotEmpty);
      expect(items, isNot(contains('Listede yok')));
      final link = _key('rifle-not-listed');
      expect(link, findsOneWidget);
      expect(
        find.descendant(
          of: link,
          matching: find.text('Aradığın tüfek listede yok mu?'),
        ),
        findsOneWidget,
      );

      await chooseInSelect(tester, 'rifle-brand-select', items.first!);
      await tapNotListed(tester, 'rifle-not-listed');
      expect(_key('rifle-brand-select'), findsNothing);
      expect(_text(tester, 'rifle-brand'), isEmpty);
      expect(_text(tester, 'rifle-model'), isEmpty);
      expect(_key('rifle-not-listed'), findsNothing);
      // The way back to the lists stays.
      expect(_key('rifle-back-to-list'), findsOneWidget);
      // A Kalibre pick keeps the typed boxes.
      if (firearm) {
        await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
        expect(_key('rifle-brand'), findsOneWidget);
        expect(_text(tester, 'rifle-brand'), isEmpty);
      }
    });
  }

  testWidgets('Ateşli: ammo Marka has no "Listede yok"; the link types', (
    tester,
  ) async {
    await _openNew(tester, firearm: true);
    expect(_key('ammo-brand-select'), findsOneWidget);
    expect(_items(tester, 'ammo-brand-select'), isNot(contains('Listede yok')));
    final link = _key('ammo-not-listed');
    expect(link, findsOneWidget);
    expect(
      find.descendant(
        of: link,
        matching: find.text('Aradığın mühimmat listede yok mu?'),
      ),
      findsOneWidget,
    );
    await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
    await chooseInSelect(tester, 'ammo-brand-select', 'Hornady');
    await tapNotListed(tester, 'ammo-not-listed');
    expect(_key('ammo-brand-select'), findsNothing);
    expect(_text(tester, 'ammo-brand'), isEmpty);
    expect(_text(tester, 'ammo-model'), isEmpty);
    expect(_key('ammo-not-listed'), findsNothing);
    expect(_key('ammo-back-to-list'), findsOneWidget);

    // Switching Tür clears the ammunition: the lists and the link return.
    await chooseInSelect(tester, 'profile-platform', 'PCP Tüfek');
    await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
    expect(_key('ammo-brand-select'), findsOneWidget);
    expect(_key('ammo-not-listed'), findsOneWidget);
  });

  testWidgets('PCP: no ammo Marka list (PCP_AMMO_BRAND off), so no link', (
    tester,
  ) async {
    await _openNew(tester, firearm: false);
    expect(_key('ammo-brand-select'), findsNothing);
    expect(_key('ammo-not-listed'), findsNothing);
    expect(_key('ammo-type'), findsOneWidget);
  });

  testWidgets('typed rifle keeps its typed mode after a Kalibre change', (
    tester,
  ) async {
    await _openNew(tester, firearm: true);
    await tapNotListed(tester, 'rifle-not-listed');
    await enterRifleField(tester, 'rifle-brand', 'Atölyem');
    await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
    expect(_text(tester, 'rifle-brand'), 'Atölyem');
    expect(_key('rifle-not-listed'), findsNothing);
    // The ammunition lists for the caliber are still offered.
    expect(_key('ammo-not-listed'), findsOneWidget);
  });

  testWidgets('Kalibre keeps "Fişeğim listede yok"', (tester) async {
    await _openNew(tester, firearm: true);
    await tester.ensureVisible(_key('rifle-caliber'));
    await tester.tap(_key('rifle-caliber'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Fişeğim listede yok'),
      find.byType(Scrollable).last,
      const Offset(0, -400),
    );
    expect(find.text('Fişeğim listede yok'), findsWidgets);
  });

  testWidgets('the scope link still opens the typed scope', (tester) async {
    await _openNew(tester, firearm: true);
    expect(_key('scope-not-listed'), findsOneWidget);
    await openScopeManual(tester);
    expect(_key('scope-brand'), findsOneWidget);
    expect(_key('scope-not-listed'), findsNothing);
  });

  group('Profili Düzenle', () {
    setUp(
      () => CatalogRepository.installUserCatalog(
        const UserCatalog(rifles: [_typedRifle], ammunition: [_typedAmmo]),
      ),
    );
    tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

    testWidgets('a typed rifle and ammunition open in typed mode', (
      tester,
    ) async {
      await _openSaved(
        tester,
        const RifleProfile(
          id: 'p-typed-link',
          name: 'Elle Girilen',
          rifleId: 'user-typed-rifle-link',
          ammunitionId: 'user-typed-ammo-link',
          scopeId: 'removed-scope-id',
          muzzleVelocityMps: 800,
          zeroRangeM: 100,
          sightHeightMm: 50,
        ),
      );
      expect(_text(tester, 'rifle-brand'), 'Atölyem');
      expect(_text(tester, 'rifle-model'), 'Özel Yapım');
      expect(_key('rifle-not-listed'), findsNothing);
      expect(_key('rifle-back-to-list'), findsOneWidget);
      expect(_text(tester, 'ammo-brand'), 'Kendi Dolumum');
      expect(_text(tester, 'ammo-model'), 'Yarışma 175');
      expect(_key('ammo-not-listed'), findsNothing);
      // Back to the lists: the link shows again.
      await tester.ensureVisible(_key('rifle-back-to-list'));
      await tester.tap(_key('rifle-back-to-list'));
      await tester.pumpAndSettle();
      expect(_key('rifle-brand-select'), findsOneWidget);
      expect(_key('rifle-not-listed'), findsOneWidget);
    });
  });
}
