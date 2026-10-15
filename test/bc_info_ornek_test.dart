// BC ⓘ örneği (owner, 2026-10-15 23:00): "Info'ya örnek: BC değerini 0,324
// şeklinde giriniz." The BC box has no unit; the ⓘ shows how to type the
// value (decimal comma). Firearm 0,324; PCP pellet 0,032; Eşik altı BC 0,310.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profile_field_info.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/rifle_form.dart';

Future<void> _openNew(WidgetTester tester, MemoryProfileStore store) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
}

/// Ateşli tüfek, typed round, BC typed as [bc]; returns the saved round.
Future<Ammunition> _saveFirearmBc(WidgetTester tester, String bc) async {
  final store = MemoryProfileStore();
  await _openNew(tester, store);
  await fillRifleForm(tester, caliber: '.308 Win');
  await fillScopeForm(tester);
  await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
  await openAmmoManual(tester);
  await chooseInSelect(tester, 'ammo-brand-pick', 'Diğer');
  await enterRifleField(tester, 'ammo-brand', 'Atölye Fişek');
  await enterRifleField(tester, 'ammo-model', 'Özel 1');
  await chooseInSelect(tester, 'ammo-grain-select', '168 gr (10,9 g)');
  await enterRifleField(tester, 'ammo-bc', bc);
  await chooseInSelect(tester, 'ammo-bc-model', 'G1');
  await fillShotValues(tester, velocityFps: '2650', zero: '100', sight: '45');
  await tester.tap(find.text('Kaydet'));
  await tester.pumpAndSettle();
  final saved = (await store.all()).single;
  return CatalogRepository.allAmmunition.singleWhere(
    (x) => x.id == saved.ammunitionId,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  test('firearm BC ⓘ ends with the 0,324 example', () {
    expect(
      ProfileFieldInfo.bcFirearm,
      endsWith(
        'Rüzgâr sapması bu değerle hesaplanır. '
        'Örnek: BC değerini 0,324 şeklinde girin.',
      ),
    );
    expect(ProfileFieldInfo.bcFirearm, contains('Tipik: G1 0,25–0,60'));
  });

  test('PCP BC ⓘ ends with a pellet example 0,032', () {
    expect(
      ProfileFieldInfo.bc,
      endsWith('sonuç yaklaşık olur. Örnek: BC değerini 0,032 şeklinde girin.'),
    );
    expect(ProfileFieldInfo.bc, contains('pellet 0,02–0,04'));
    expect(ProfileFieldInfo.bc, isNot(contains('0,324')));
  });

  test('Eşik altı BC ⓘ uses a firearm example 0,310', () {
    expect(
      ProfileFieldInfo.bandBc,
      endsWith(
        'Boş bırakırsanız tek BC kullanılır. '
        'Örnek: BC değerini 0,310 şeklinde girin.',
      ),
    );
    expect(ProfileFieldInfo.bandBc, isNot(contains('0,031')));
  });

  testWidgets('firearm BC typed "0,324" saves 0.324', (tester) async {
    final a = await _saveFirearmBc(tester, '0,324');
    expect(a.ballisticCoefficient, 0.324);
    expect(a.ballisticModel, BallisticModel.g1);
  });

  testWidgets('firearm BC typed "0.324" saves 0.324 too', (tester) async {
    final a = await _saveFirearmBc(tester, '0.324');
    expect(a.ballisticCoefficient, 0.324);
  });
}
