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

const _stale = RifleProfile(
  id: 'stale',
  name: 'Eski Profil',
  rifleId: 'removed-rifle-id',
  ammunitionId: 'removed-ammo-id',
  scopeId: 'removed-scope-id',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 180,
);

const _valid = RifleProfile(
  id: 'valid',
  name: 'Gecerli Profil',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

Future<MemoryProfileStore> _pumpAndOpen(
  WidgetTester tester,
  RifleProfile profile,
) async {
  tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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
  return store;
}

VoidCallback? _updateAction(WidgetTester tester) => tester
    .widget<MenzilPrimaryButton>(
      find.widgetWithText(MenzilPrimaryButton, 'Güncelle'),
    )
    .onPressed;

void main() {
  _unitsAndFirearmTests();
  testWidgets(
    'editing a profile with unresolved catalog ids never substitutes a catalog entry',
    (tester) async {
      final store = await _pumpAndOpen(tester, _stale);
      expect(find.text('Profili Düzenle'), findsOneWidget);
      expect(find.textContaining('sessizce seçilmedi'), findsOneWidget);
      expect(
        _updateAction(tester),
        isNull,
        reason: 'Güncelle must stay disabled until the user picks explicitly',
      );
      // Nothing was written.
      final stored = (await store.all()).single;
      expect(stored.rifleId, 'removed-rifle-id');
      expect(stored.ammunitionId, 'removed-ammo-id');
      expect(stored.scopeId, 'removed-scope-id');
    },
  );

  testWidgets(
    'a catalog-rifle profile is prefilled but needs the twist before Güncelle',
    (tester) async {
      await _pumpAndOpen(tester, _valid);
      expect(find.textContaining('sessizce seçilmedi'), findsNothing);
      // Brand, model and caliber come from the old catalog record so the
      // user can correct them; twist was never stored, so it is required.
      String text(String key) => tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(Key(key)),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text;
      expect(
        find.descendant(
          of: find.byKey(const Key('rifle-caliber')),
          matching: find.text('6.35 mm (.25)'),
        ),
        findsOneWidget,
      );
      // Namlu uzunluğu is not asked any more (owner, 2026-10-09).
      expect(find.byKey(const Key('rifle-barrel')), findsNothing);
      expect(text('rifle-twist-rate'), isEmpty);
      expect(_updateAction(tester), isNull);

      // The old catalog scope is prefilled into the scope form.
      expect(
        find.descendant(
          of: find.byKey(const Key('scope-brand-select')),
          matching: find.text('Gazi Sniper'),
        ),
        findsOneWidget,
      );
      // Its values come from the record; the boxes are hidden (owner,
      // 2026-10-13) and the designation shows them.
      expect(find.byKey(const Key('scope-max-mag')), findsNothing);
      expect(find.text('Dürbün: Gazi Sniper 6-36x56 FFP'), findsOneWidget);

      await enterRifleField(tester, 'rifle-twist-rate', '16');
      await chooseTwistDirection(tester, 'Sol');
      // Regülatör basıncı is not asked any more (owner, 2026-10-09).
      expect(find.byKey(const Key('rifle-regulator')), findsNothing);
      // PCP BC may stay empty now (owner, 2026-10-12).
      expect(
        _updateAction(tester),
        isNotNull,
        reason: 'a PCP pellet without a published BC can be saved',
      );
      expect(text('ammo-grain'), '51');
      await enterRifleField(tester, 'ammo-bc', '0,08');
      await chooseBcModel(tester, 'G1');
      expect(_updateAction(tester), isNotNull);
    },
  );

  testWidgets('out-of-range rifle values show an error and block saving', (
    tester,
  ) async {
    await _pumpAndOpen(tester, _valid);
    await enterRifleField(tester, 'ammo-bc', '0,08');
    await chooseBcModel(tester, 'G1');
    await chooseTwistDirection(tester, 'Sağ');
    await enterRifleField(tester, 'rifle-twist-rate', '200');
    expect(find.text('3–80 arasında bir değer girin.'), findsOneWidget);
    expect(_updateAction(tester), isNull);
    await enterRifleField(tester, 'rifle-twist-rate', '1,5');
    expect(_updateAction(tester), isNull);
    await enterRifleField(tester, 'rifle-twist-rate', '9');
    expect(_updateAction(tester), isNotNull);
    // Maximum magnification below the minimum is rejected (a typed scope:
    // a catalog scope's büyütme boxes are hidden).
    await fillScopeForm(tester);
    expect(_updateAction(tester), isNotNull);
    await chooseInSelect(tester, 'scope-max-mag', '4x');
    expect(find.text('Minimum büyütmeden küçük olamaz.'), findsOneWidget);
    expect(_updateAction(tester), isNull);
    await chooseInSelect(tester, 'scope-max-mag', '24x');
    expect(_updateAction(tester), isNotNull);
    // Kalibre is a list now: no free (out-of-range) typing.
    expect(
      find.descendant(
        of: find.byKey(const Key('rifle-caliber')),
        matching: find.byType(TextField),
      ),
      findsNothing,
    );
    // A BC outside the plausible range is rejected.
    await enterRifleField(tester, 'ammo-bc', '3');
    expect(find.text('0,005–1,5 arasında bir değer girin.'), findsOneWidget);
    expect(_updateAction(tester), isNull);
  });

  testWidgets('every typed value has an ⓘ explanation; BC opens its text', (
    tester,
  ) async {
    await _pumpAndOpen(tester, _valid);
    for (final label in const [
      'Kalibre',
      'Namlu yiv yönü',
      'Yiv oranı',
      'Tip',
      'Ağırlık',
      'BC',
      // BC modeli on PCP too since 2026-10-14 (owner), G1 by default.
      'BC modeli',
      'Dürbün ayağı',
      'Üst kule klik sayısı',
      'Sight height',
      'Namlu çıkış hızı',
      'Sıfırlama mesafesi',
      // PCP tüp ve regülatör basıncı (owner, 2026-10-12), optional.
      'Tüp basıncı',
      'Regülatör basıncı',
      '1. basınç',
      '1. hız',
    ]) {
      expect(find.byTooltip('Bilgi: $label'), findsOneWidget, reason: label);
    }
    // A catalog scope: its values come from the record, the boxes are
    // hidden (owner, 2026-10-13); Klik değeri is asked only when typed.
    const scopeLabels = [
      'Odak düzlemi',
      'Minimum büyütme',
      'Maksimum büyütme',
      'Mercek çapı',
      'Dürbün birimi',
      'Klik değeri',
    ];
    // The Odak düzlemi filter (approved design, owner 2026-10-16) has its
    // own ⓘ; the hidden value box must not.
    final filters = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('scope-filter-'),
    );
    for (final label in scopeLabels) {
      final all = find.byTooltip('Bilgi: $label').evaluate().length;
      final inFilters = find
          .descendant(of: filters, matching: find.byTooltip('Bilgi: $label'))
          .evaluate()
          .length;
      expect(all - inFilters, 0, reason: label);
    }
    final bcInfo = find.byTooltip('Bilgi: BC');
    await tester.ensureVisible(bcInfo);
    await tester.tap(bcInfo);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('havayı ne kadar kolay yardığını'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('havayı ne kadar kolay yardığını'),
      findsNothing,
    );
    // A typed scope asks each of them, every one with its ⓘ.
    await openScopeManual(tester);
    for (final label in scopeLabels) {
      expect(find.byTooltip('Bilgi: $label'), findsOneWidget, reason: label);
    }
  });
}

// Owner, 2026-10-09: yard profiles and SMOA turrets; firearm texts.
void _unitsAndFirearmTests() {
  testWidgets('Mesafe birimi Yard converts the zero and is saved', (
    tester,
  ) async {
    // Saving writes the personal rifle/scope/ammo records too.
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));
    final store = await _pumpAndOpen(tester, _valid);
    await enterRifleField(tester, 'ammo-bc', '0,08');
    await chooseBcModel(tester, 'G1');
    await chooseTwistDirection(tester, 'Sağ');
    await enterRifleField(tester, 'rifle-twist-rate', '16');
    String zero() => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('profile-zero')),
            matching: find.byType(TextField),
          ),
        )
        .controller!
        .text;
    expect(zero(), '25');
    await chooseInSelect(tester, 'profile-distance-unit', 'Yard');
    // 25 m = 27.3 yd (no unit label next to the field; ⓘ explains it).
    expect(zero(), '27.3');
    // SMOA is offered as a turret unit (a typed scope: a catalog scope
    // brings its own unit and hides the box, owner 2026-10-13).
    await fillScopeForm(tester, unit: 'SMOA', click: '1/4 SMOA');
    expect(_updateAction(tester), isNotNull);
    final update = find.widgetWithText(MenzilPrimaryButton, 'Güncelle');
    await tester.ensureVisible(update);
    await tester.tap(update);
    await tester.pumpAndSettle();
    final saved = (await store.all()).single;
    expect(saved.distanceUnit, DistanceUnit.yard);
    // Stored in metres: 27.3 yd = 24.96 m.
    expect(saved.zeroRangeM, closeTo(24.96, 0.01));
    expect(saved.angularUnit, AngularUnit.smoa);
  });

  testWidgets('Ateşli tüfek: one cartridge per row, no free typing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
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
    await chooseInSelect(tester, 'rifle-caliber', '.30-06 Springfield');
    // The half-width box (owner, 2026-10-13) may show the short form.
    expect(
      find.descendant(
        of: find.byKey(const Key('rifle-caliber')),
        matching: find.textContaining('.30-06'),
      ),
      findsOneWidget,
    );
    expect(find.text('Diğer (elle yaz)'), findsNothing);
    expect(find.byKey(const Key('rifle-caliber-other')), findsNothing);
  });

  testWidgets('Ateşli tüfek: firearm caliber and ammunition texts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
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
    await chooseInSelect(tester, 'profile-platform', 'PCP Tüfek');
    // PCP calibers to pick from.
    await chooseInSelect(tester, 'rifle-caliber', '5.50 mm (.22)');
    await tester.tap(find.byKey(const Key('rifle-caliber')));
    await tester.pumpAndSettle();
    for (final c in const [
      '4.50 mm (.177)',
      '6.35 mm (.25)',
      '7.62 mm (.30)',
      '9.00 mm (.357)',
    ]) {
      expect(find.text(c), findsWidgets, reason: c);
    }
    await tester.tap(find.text('9.00 mm (.357)').last);
    await tester.pumpAndSettle();
    // No example inside the boxes: an example reads like a value (owner,
    // 2026-10-11). Examples live in the ⓘ.
    final grain = find.descendant(
      of: find.byKey(const Key('ammo-grain')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(grain);
    expect(tester.widget<TextField>(grain).decoration!.hintText, isNull);

    await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
    // 9.00 mm is not a firearm caliber here: the choice is cleared, and the
    // firearm list is offered.
    expect(find.text('9.00 mm (.357)'), findsNothing);
    await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
    expect(tester.widget<TextField>(grain).decoration!.hintText, isNull);
    // Marka is a list of the firearm rounds for this caliber; a typed
    // round opens from the "listede yok mu?" link (owner, 2026-10-14), a
    // typed brand only after "Diğer", without a pellet example.
    expect(find.byKey(const Key('ammo-brand-select')), findsOneWidget);
    await openAmmoManual(tester);
    await chooseInSelect(tester, 'ammo-brand-pick', 'Diğer');
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('ammo-brand')),
              matching: find.byType(TextField),
            ),
          )
          .decoration!
          .hintText,
      isNull,
    );
    // No pellet/slug choice for a firearm: Fabrika fişeği / El dolumu.
    expect(find.byKey(const Key('ammo-type')), findsNothing);
    expect(find.byKey(const Key('ammo-source')), findsOneWidget);
    final grainInfo = find.byTooltip('Bilgi: Ağırlık');
    await tester.ensureVisible(grainInfo);
    await tester.tap(grainInfo);
    await tester.pumpAndSettle();
    expect(find.textContaining('.308 için 168 gr'), findsOneWidget);
  });

  testWidgets('switching to Ateşli tüfek empties the PCP ammunition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
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
    await chooseInSelect(tester, 'profile-platform', 'PCP Tüfek');
    // PCP asks no Marka (owner, 2026-10-13) and no Uzunluk (owner,
    // 2026-10-13 23:32: only Pro > Mermi uzunluğu): type a weight.
    expect(find.byKey(const Key('ammo-brand-select')), findsNothing);
    expect(find.byKey(const Key('ammo-length')), findsNothing);
    await enterRifleField(tester, 'ammo-grain', '33,95');
    await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
    // The typed PCP values are gone; the firearm lists are offered again.
    expect(find.text('33,95'), findsNothing);
    expect(find.byKey(const Key('ammo-length')), findsNothing);
    expect(find.byKey(const Key('ammo-brand-select')), findsOneWidget);
  });
}
