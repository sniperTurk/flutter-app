// Ateşli tüfek, elle girilen mühimmat (owner, 2026-10-14; since
// 2026-10-17 through Marka "Diğer marka", test/diger_marka_test.dart):
// BC typed, BC modeli G1/G7 from "Seçiniz", barut lists, no bands; the
// listed flow is unchanged. Deleted with the old typed entry (2026-10-17):
// the typed-brand list with "Diğer", the "Listede yok" weight list, the
// Kalibre notice and "Listeye dön".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

Future<void> _openNew(WidgetTester tester, {MemoryProfileStore? store}) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store ?? MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
}

Finder _in(String key, Finder f) =>
    find.descendant(of: find.byKey(Key(key)), matching: f);

String _text(WidgetTester tester, String key) =>
    tester.widget<TextField>(_in(key, find.byType(TextField))).controller!.text;

List<T?> _values<T>(WidgetTester tester, String key) => [
  for (final i
      in tester
          .widget<MenzilSelect<T>>(_in(key, find.byType(MenzilSelect<T>)))
          .items)
    i.value,
];

List<String> _labels<T>(WidgetTester tester, String key) => [
  for (final i
      in tester
          .widget<MenzilSelect<T>>(_in(key, find.byType(MenzilSelect<T>)))
          .items)
    (i.child as Text).data!,
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('PCP: no firearm typed parts; Tip, Ağırlık, BC, BC modeli (G1)', (
    tester,
  ) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'profile-platform', 'PCP Tüfek');
    await chooseInSelect(tester, 'rifle-caliber', '5.50 mm (.22)');
    expect(find.byKey(const Key('ammo-not-listed')), findsOneWidget);
    expect(find.byKey(const Key('ammo-typed-summary')), findsNothing);
    expect(find.byKey(const Key('ammo-type')), findsOneWidget);
    expect(_in('ammo-grain', find.byType(TextField)), findsOneWidget);
    expect(_in('ammo-bc', find.byType(TextField)), findsOneWidget);
    // BC modeli on PCP since 2026-10-14 (owner): G1 selected by default.
    expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g1');
    expect(find.byKey(const Key('profile-powder-coef')), findsNothing);
  });

  testWidgets('typed firearm round: BC typed, BC modeli G1/G7, barut lists, '
      'no bands, summary', (tester) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
    await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
    await chooseOtherAmmoBrand(tester);
    await enterRifleField(tester, 'ammo-grain', '168');
    // BC typed; BC modeli G1 / G7 from "Seçiniz" (no automatic G1).
    await enterRifleField(tester, 'ammo-bc', '0,462');
    expect(selectedValue<String>(tester, 'ammo-bc-model'), isNull);
    expect(_values<String>(tester, 'ammo-bc-model'), ['g1', 'g7']);
    // Barut lists start on "Seçiniz".
    expect(selectedValue<String>(tester, 'profile-powder-coef'), isNull);
    expect(selectedValue<String>(tester, 'profile-powder-temp'), isNull);
    expect(_labels<String>(tester, 'profile-powder-coef'), [
      'Seçiniz',
      '0,25',
      '0,5',
      '0,75',
      '1',
      '1,25',
      '1,5',
      '2',
      '2,5',
      '3',
    ]);
    expect(_values<String>(tester, 'profile-powder-temp'), [
      '', '-10', '-5', '0', '5', '10', '15', '21', '25', '30', '35', '40', //
    ]);
    // Hız eşiğine göre BC hidden for a typed round (AMMO_BC_BANDS_TYPED).
    expect(find.byKey(const Key('ammo-bands-title')), findsNothing);
    expect(find.byKey(const Key('ammo-band-fps-0')), findsNothing);
    // No summary until BC modeli is there.
    expect(find.byKey(const Key('ammo-typed-summary')), findsNothing);
    await chooseInSelect(tester, 'ammo-bc-model', 'G1');
    expect(
      _in(
        'ammo-typed-summary',
        find.text(
          'Diğer marka model .308 Win · .308 Win · 168 gr (10,9 g) · BC '
          '0,462 G1',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('listed firearm round: list flow unchanged', (tester) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
    await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
    await chooseInSelect(tester, 'ammo-brand-select', 'Hornady');
    await chooseInSelect(
      tester,
      'ammo-model-select',
      'ELD Match 168 gr ELD Match',
    );
    expect(_text(tester, 'ammo-grain'), '168');
    expect(_text(tester, 'ammo-bc'), '0,263');
    expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g7');
    expect(find.byKey(const Key('ammo-grain-select')), findsNothing);
    expect(find.byKey(const Key('ammo-typed-summary')), findsNothing);
    expect(find.byKey(const Key('ammo-bands-title')), findsOneWidget);
    expect(find.byKey(const Key('ammo-not-listed')), findsOneWidget);
  });
}
