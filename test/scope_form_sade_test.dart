// Dürbün form, owner 2026-10-13: a catalog scope shows only Dürbün ayağı,
// Üst kule klik sayısı and Retikül under Model; the other values come from
// the record (boxes hidden, not deleted). A typed scope opens from the link
// "Aradığın dürbün listede yok mu?" under the card.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

const _hidden = [
  'scope-min-mag',
  'scope-max-mag',
  'scope-objective',
  'scope-focal-plane',
  'scope-unit',
];

const _filterLabels = ['Birim', 'Odak', 'Tüp', 'Büyütme'];

void _setView(WidgetTester tester) {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _openNew(WidgetTester tester) async {
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
}

String? _designation(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('scope-designation'))).data;

RifleProfile _profile(String scopeId) => RifleProfile(
  id: 'p-$scopeId',
  name: 'Dürbün Profil',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: scopeId,
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

void main() {
  testWidgets('catalog pick hides the five boxes; values stay in use', (
    tester,
  ) async {
    await _openNew(tester);
    // "Listede yok" is not in the Marka list any more.
    final brandItems = tester
        .widget<MenzilSelect<String>>(
          find.descendant(
            of: find.byKey(const Key('scope-brand-select')),
            matching: find.byType(MenzilSelect<String>),
          ),
        )
        .items;
    expect(brandItems, isNotEmpty);
    expect(
      brandItems.where(
        (i) => i.child is Text && (i.child as Text).data == 'Listede yok',
      ),
      isEmpty,
    );

    await chooseInSelect(tester, 'scope-brand-select', 'Element Optics');
    // Before a Model is chosen the five boxes stay hidden.
    for (final key in _hidden) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }
    await chooseInSelect(tester, 'scope-model-select', 'Titan 3-18x50 FFP MOA');
    for (final key in _hidden) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }
    for (final key in [
      'scope-mount',
      'scope-travel-elevation',
      'scope-reticle',
      'scope-not-listed',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    // The record's values are still filled in (and used).
    expect(_designation(tester), contains('3-18x50 FFP'));
  });

  testWidgets('a value the catalog record lacks shows only its box', (
    tester,
  ) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'scope-brand-select', 'Gamo');
    // Gamo publishes no focal plane for this model.
    await chooseInSelect(
      tester,
      'scope-model-select',
      '3-9X50 Illuminated Reticle · MOA',
    );
    expect(find.byKey(const Key('scope-focal-plane')), findsOneWidget);
    expect(selectedValue<bool>(tester, 'scope-focal-plane'), isNull);
    for (final key in _hidden.where((k) => k != 'scope-focal-plane')) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }
    expect(find.byTooltip('Bilgi: Odak düzlemi'), findsOneWidget);
    // Filled in by the user, the box stays.
    await chooseFocalPlane(tester, 'SFP');
    expect(find.byKey(const Key('scope-focal-plane')), findsOneWidget);
    expect(_designation(tester), contains('3-9x50 SFP'));
  });

  testWidgets('"Aradığın dürbün listede yok mu?" opens the typed entry', (
    tester,
  ) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'scope-brand-select', 'Element Optics');
    await chooseInSelect(tester, 'scope-model-select', 'Titan 3-18x50 FFP MOA');
    expect(find.text('Aradığın dürbün listede yok mu?'), findsOneWidget);
    await openScopeManual(tester);
    // Typed Marka, every value box incl. Klik değeri on "Seçiniz".
    expect(find.byKey(const Key('scope-brand')), findsOneWidget);
    expect(find.byKey(const Key('scope-brand-select')), findsNothing);
    for (final key in [..._hidden, 'scope-click']) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(selectedValue<double>(tester, 'scope-max-mag'), isNull);
    expect(_designation(tester), 'Dürbün: —');
    expect(find.byKey(const Key('scope-not-listed')), findsNothing);
    // Retikül offers the plain drawings of the chosen unit.
    await chooseInSelect(tester, 'scope-unit', 'MRAD');
    await tester.ensureVisible(find.byKey(const Key('scope-reticle')));
    await tester.tap(find.byKey(const Key('scope-reticle')));
    await tester.pumpAndSettle();
    expect(find.text('Duplex'), findsWidgets);
    expect(find.text('MOA çizgili'), findsNothing);
    expect(find.text('MIL çizgili'), findsWidgets);
    await tester.tap(find.text('Duplex').last);
    await tester.pumpAndSettle();

    // "Listeden seç" returns to the lists.
    final back = find.byKey(const Key('scope-back-to-list'));
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scope-brand-select')), findsOneWidget);
    expect(find.byKey(const Key('scope-not-listed')), findsOneWidget);
    for (final key in _hidden) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }
  });

  testWidgets('Profili Düzenle of a catalog scope hides the filters', (
    tester,
  ) async {
    await _openSaved(tester, _profile('gazi-6-36'));
    expect(
      find.descendant(
        of: find.byKey(const Key('scope-brand-select')),
        matching: find.text('Gazi Sniper'),
      ),
      findsOneWidget,
    );
    for (final label in _filterLabels) {
      expect(find.byTooltip('Bilgi: $label'), findsNothing, reason: label);
    }
    for (final key in _hidden) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }
    expect(find.text('Dürbün: Gazi Sniper 6-36x56 FFP'), findsOneWidget);
    // Another Marka shows the filters again.
    await chooseInSelect(tester, 'scope-brand-select', 'Element Optics');
    for (final label in _filterLabels) {
      expect(find.byTooltip('Bilgi: $label'), findsOneWidget, reason: label);
    }
  });

  testWidgets('Profili Düzenle of a typed scope shows the typed values', (
    tester,
  ) async {
    CatalogRepository.installUserCatalog(
      const UserCatalog(
        scopes: [
          ScopeOptic(
            id: 'user-scope-benim',
            brand: 'Benim Optik',
            model: '',
            objectiveDiameterMm: 44,
            clickValue: 0.1,
            clickUnit: AngularUnit.mrad,
            minMagnification: 4,
            maxMagnification: 16,
            firstFocalPlane: true,
            userEntered: true,
          ),
        ],
      ),
    );
    addTearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));
    await _openSaved(tester, _profile('user-scope-benim'));
    final brand = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('scope-brand')),
        matching: find.byType(TextField),
      ),
    );
    expect(brand.controller!.text, 'Benim Optik');
    expect(selectedValue<double>(tester, 'scope-min-mag'), 4);
    expect(selectedValue<double>(tester, 'scope-max-mag'), 16);
    expect(selectedValue<double>(tester, 'scope-objective'), 44);
    expect(selectedValue<bool>(tester, 'scope-focal-plane'), isTrue);
    expect(find.byKey(const Key('scope-click')), findsOneWidget);
    for (final label in _filterLabels) {
      expect(find.byTooltip('Bilgi: $label'), findsNothing, reason: label);
    }
    expect(find.byKey(const Key('scope-not-listed')), findsNothing);
  });
}
