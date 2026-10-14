// Ateşli tüfek, elle girilen mühimmat (owner, 2026-10-14): the typed round
// opens from "Aradığın mühimmat listede yok mu?"; every value except BC is
// picked from a list (Marka with "Diğer", Ağırlık as "168 gr (10,9 g)" with
// "Listede yok" + a plausibility range, BC modeli G1/G7, barut lists); a
// summary line sits above Kaydet. PCP Mühimmat is unchanged.
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

/// .308 Win, Fabrika fişeği, then the link.
Future<void> _typed308(WidgetTester tester) async {
  await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
  await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
  await openAmmoManual(tester);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('firearm: link under Marka | Model, no "Listede yok" item', (
    tester,
  ) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
    await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
    final link = find.byKey(const Key('ammo-not-listed'));
    expect(link, findsOneWidget);
    expect(
      _in('ammo-not-listed', find.text('Aradığın mühimmat listede yok mu?')),
      findsOneWidget,
    );
    // Under the Model row, left-aligned.
    final model = tester.getRect(find.byKey(const Key('ammo-model-select')));
    final l = tester.getRect(link);
    expect(l.top, greaterThanOrEqualTo(model.bottom - 1));
    final card = tester.getRect(find.byKey(const Key('profile-ammo-form')));
    expect(l.left - card.left, lessThan(40));
    // "Listede yok" hidden (AMMO_LISTEDE_YOK off), not removed.
    expect(
      _values<String>(tester, 'ammo-brand-select'),
      isNot(contains('__manual')),
    );
    expect(_values<String>(tester, 'ammo-brand-select'), contains('Hornady'));
    // El dolumu: the same link.
    await chooseInSelect(tester, 'ammo-source', 'El dolumu');
    expect(find.byKey(const Key('ammo-not-listed')), findsOneWidget);
    // The link opens the typed entry; "Listeye dön" goes back to the list.
    await openAmmoManual(tester);
    expect(find.byKey(const Key('ammo-not-listed')), findsNothing);
    expect(find.byKey(const Key('ammo-brand-pick')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('ammo-back-to-list')));
    await tester.tap(find.byKey(const Key('ammo-back-to-list')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ammo-brand-select')), findsOneWidget);
    expect(find.byKey(const Key('ammo-not-listed')), findsOneWidget);
  });

  testWidgets('PCP: no link; Tip | Ağırlık | BC | BC modeli (G1)', (
    tester,
  ) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'profile-platform', 'PCP Tüfek');
    await chooseInSelect(tester, 'rifle-caliber', '5.50 mm (.22)');
    expect(find.byKey(const Key('ammo-not-listed')), findsNothing);
    expect(find.byKey(const Key('ammo-brand-pick')), findsNothing);
    expect(find.byKey(const Key('ammo-grain-select')), findsNothing);
    expect(find.byKey(const Key('ammo-typed-summary')), findsNothing);
    expect(find.byKey(const Key('ammo-type')), findsOneWidget);
    expect(_in('ammo-grain', find.byType(TextField)), findsOneWidget);
    expect(_in('ammo-bc', find.byType(TextField)), findsOneWidget);
    // BC modeli on PCP since 2026-10-14 (owner): G1 selected by default.
    expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g1');
    expect(find.byKey(const Key('profile-powder-coef')), findsNothing);
  });

  testWidgets('typed firearm round: lists, typed Model and BC, no bands', (
    tester,
  ) async {
    await _openNew(tester);
    await _typed308(tester);
    // Marka: every known brand, sorted, "Diğer" last.
    final brands = _values<String>(tester, 'ammo-brand-pick');
    expect(brands.last, '__other');
    expect(_labels<String>(tester, 'ammo-brand-pick').last, 'Diğer');
    expect(
      brands,
      containsAll(<String>['Federal', 'Hornady', 'Sellier & Bellot']),
    );
    expect(selectedValue<String>(tester, 'ammo-brand-pick'), isNull);
    expect(find.byKey(const Key('ammo-brand')), findsNothing);
    await chooseInSelect(tester, 'ammo-brand-pick', 'Diğer');
    expect(_in('ammo-brand', find.byType(TextField)), findsOneWidget);
    await chooseInSelect(tester, 'ammo-brand-pick', 'Federal');
    expect(find.byKey(const Key('ammo-brand')), findsNothing);
    // Model typed.
    expect(_in('ammo-model', find.byType(TextField)), findsOneWidget);
    // Ağırlık: grain with grams, ascending, "Listede yok" last.
    final weights = _labels<double>(tester, 'ammo-grain-select');
    expect(weights, contains('168 gr (10,9 g)'));
    expect(weights, contains('175 gr (11,3 g)'));
    expect(weights.last, 'Listede yok');
    final values = _values<double>(tester, 'ammo-grain-select')..removeLast();
    expect(values, orderedEquals([...values]..sort()));
    expect(selectedValue<double>(tester, 'ammo-grain-select'), isNull);
    expect(find.byKey(const Key('ammo-grain')), findsNothing);
    // "Listede yok": a typed grain box with grams and a range check.
    await chooseInSelect(tester, 'ammo-grain-select', 'Listede yok');
    await enterRifleField(tester, 'ammo-grain', '11');
    expect(
      find.text(
        'Bu ağırlık bu kalibre için mantıklı değil. Kutudaki değeri kontrol '
        'edin.',
      ),
      findsOneWidget,
    );
    await enterRifleField(tester, 'ammo-grain', '173');
    expect(find.textContaining('mantıklı değil'), findsNothing);
    expect(_in('ammo-grain', find.text('gr = 11,2 g')), findsOneWidget);
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
    // No summary until Model and BC modeli are there.
    expect(find.byKey(const Key('ammo-typed-summary')), findsNothing);
    await enterRifleField(tester, 'ammo-model', 'Gold Medal');
    await chooseInSelect(tester, 'ammo-grain-select', '168 gr (10,9 g)');
    expect(find.byKey(const Key('ammo-grain')), findsNothing);
    await chooseInSelect(tester, 'ammo-bc-model', 'G1');
    expect(
      _in(
        'ammo-typed-summary',
        find.text(
          'Federal Gold Medal · .308 Win · 168 gr (10,9 g) · BC 0,462 G1',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('without a Kalibre Ağırlık is a notice, not a typed box', (
    tester,
  ) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
    await openAmmoManual(tester);
    expect(find.byKey(const Key('ammo-grain-need-caliber')), findsOneWidget);
    expect(find.byKey(const Key('ammo-grain-select')), findsNothing);
    expect(find.byKey(const Key('ammo-grain')), findsNothing);
    // The Kalibre brings the list.
    await chooseInSelect(tester, 'rifle-caliber', '6.5 Creedmoor');
    expect(find.byKey(const Key('ammo-grain-need-caliber')), findsNothing);
    expect(
      _labels<double>(tester, 'ammo-grain-select'),
      contains('140 gr (9,1 g)'),
    );
  });

  testWidgets('a weight of another Kalibre is not taken silently', (
    tester,
  ) async {
    await _openNew(tester);
    await _typed308(tester);
    await chooseInSelect(tester, 'ammo-grain-select', '168 gr (10,9 g)');
    await chooseInSelect(tester, 'rifle-caliber', '.223 Rem');
    // 168 gr is no .223 weight: the box is empty again and Kaydet says why.
    expect(selectedValue<double>(tester, 'ammo-grain-select'), isNull);
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-missing'))).data,
      contains('Ağırlık'),
    );
  });

  testWidgets('save + reopen keeps every typed value', (tester) async {
    final store = MemoryProfileStore();
    await _openNew(tester, store: store);
    await fillRifleForm(tester, caliber: '.308 Win');
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
    expect(find.byKey(const Key('ammo-typed-summary')), findsOneWidget);
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    final saved = (await store.all()).single;
    expect(saved.powderTempCoefPercentPer15C, 1.5);
    expect(saved.powderTempReferenceC, 21);
    final a = CatalogRepository.allAmmunition.singleWhere(
      (x) => x.id == saved.ammunitionId,
    );
    expect(a.brand, 'Atölye Fişek');
    expect(a.model, 'Özel 1');
    expect(a.grain, 173);
    expect(a.ballisticCoefficient, 0.5);
    expect(a.ballisticModel, BallisticModel.g7);
    expect(a.bcBands, isEmpty);

    await tester.tap(find.text(saved.name).first);
    await tester.pumpAndSettle();
    expect(find.text('Profili Düzenle'), findsOneWidget);
    expect(selectedValue<String>(tester, 'ammo-brand-pick'), '__other');
    expect(_text(tester, 'ammo-brand'), 'Atölye Fişek');
    expect(_text(tester, 'ammo-model'), 'Özel 1');
    expect(selectedValue<double>(tester, 'ammo-grain-select'), -1);
    expect(_text(tester, 'ammo-grain'), '173');
    expect(selectedValue<String>(tester, 'ammo-bc-model'), 'g7');
    expect(selectedValue<String>(tester, 'profile-powder-coef'), '1,5');
    expect(selectedValue<String>(tester, 'profile-powder-temp'), '21');
    expect(find.byKey(const Key('ammo-typed-summary')), findsOneWidget);
    expect(
      tester
          .widget<MenzilPrimaryButton>(
            find.widgetWithText(MenzilPrimaryButton, 'Güncelle'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('an older typed profile keeps off-list values and its bands', (
    tester,
  ) async {
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries(const [
        {
          'id': 'manual_rifle_old',
          'kind': 'rifle',
          'platform': 'firearm',
          'brand': 'Atölye',
          'model': 'Özel',
          'caliberMm': 7.82,
          'twistDirection': 'right',
          'twistRateIn': 10,
        },
        {
          'id': 'manual_ammo_old',
          'kind': 'ammo',
          'platform': 'firearm',
          'brand': 'Eski Marka',
          'model': 'Eski Fişek',
          'caliberMm': 7.82,
          'grain': 175,
          'ammoType': 'bullet',
          'bc': 0.475,
          'bcModel': 'g1',
          'bcBands': [
            {'mps': 700.0, 'bc': 0.475},
            {'mps': 550.0, 'bc': 0.46},
            {'mps': 0.0, 'bc': 0.44},
          ],
        },
        {
          'id': 'manual_scope_old',
          'kind': 'scope',
          'platform': 'firearm',
          'brand': 'Optik',
          'model': '5-25x56',
          'objectiveMm': 56,
          'click': 0.1,
          'clickUnit': 'mrad',
          'focal': 'ffp',
          'minMag': 5,
          'maxMag': 25,
        },
      ]),
    );
    final store = MemoryProfileStore();
    await store.save(
      const RifleProfile(
        id: 'old',
        name: 'Eski Profil',
        rifleId: 'manual_rifle_old',
        ammunitionId: 'manual_ammo_old',
        scopeId: 'manual_scope_old',
        muzzleVelocityMps: 800,
        zeroRangeM: 100,
        sightHeightMm: 45,
        powderTempCoefPercentPer15C: 0.8,
        powderTempReferenceC: 20,
      ),
    );
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
    await tester.tap(find.text('Eski Profil').first);
    await tester.pumpAndSettle();
    // Typed mode: unknown brand as "Diğer" + typed.
    expect(selectedValue<String>(tester, 'ammo-brand-pick'), '__other');
    expect(_text(tester, 'ammo-brand'), 'Eski Marka');
    // Off-list Barut values stay and are marked "(kayıtlı)".
    expect(selectedValue<String>(tester, 'profile-powder-coef'), '0,8');
    expect(
      _in('profile-powder-coef', find.text('0,8 (kayıtlı)')),
      findsOneWidget,
    );
    expect(selectedValue<String>(tester, 'profile-powder-temp'), '20');
    expect(
      _in('profile-powder-temp', find.text('20 (kayıtlı)')),
      findsOneWidget,
    );
    // Bands hidden for a typed round, but kept.
    expect(find.byKey(const Key('ammo-bands-title')), findsNothing);
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();
    final saved = (await store.all()).single;
    expect(saved.powderTempCoefPercentPer15C, 0.8);
    expect(saved.powderTempReferenceC, 20);
    final a = CatalogRepository.allAmmunition.singleWhere(
      (x) => x.id == saved.ammunitionId,
    );
    expect(a.bcBands, hasLength(3));
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
