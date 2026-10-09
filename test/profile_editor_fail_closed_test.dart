import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      expect(text('rifle-caliber'), '6.35');
      // Namlu uzunluğu is not asked any more (owner, 2026-10-09).
      expect(find.byKey(const Key('rifle-barrel')), findsNothing);
      expect(text('rifle-twist-rate'), isEmpty);
      expect(_updateAction(tester), isNull);

      // The old catalog scope is prefilled into the scope form.
      expect(text('scope-brand'), 'Gazi Sniper');
      expect(text('scope-max-mag'), '36');
      expect(find.text('Dürbün: Gazi Sniper 6-36x56 FFP'), findsOneWidget);

      await enterRifleField(tester, 'rifle-twist-rate', '16');
      await chooseTwistDirection(tester, 'Sol');
      // Regülatör basıncı is not asked any more (owner, 2026-10-09).
      expect(find.byKey(const Key('rifle-regulator')), findsNothing);
      expect(
        _updateAction(tester),
        isNull,
        reason: 'the old catalog ammo has no BC; it must be entered',
      );
      expect(text('ammo-grain'), '51');
      await enterRifleField(tester, 'ammo-bc', '0,08');
      await chooseInSelect(tester, 'ammo-bc-model', 'G1');
      expect(_updateAction(tester), isNotNull);
    },
  );

  testWidgets('out-of-range rifle values show an error and block saving', (
    tester,
  ) async {
    await _pumpAndOpen(tester, _valid);
    await enterRifleField(tester, 'ammo-bc', '0,08');
    await chooseInSelect(tester, 'ammo-bc-model', 'G1');
    await chooseTwistDirection(tester, 'Sağ');
    await enterRifleField(tester, 'rifle-twist-rate', '200');
    expect(find.text('3–80 arasında bir değer girin.'), findsOneWidget);
    expect(_updateAction(tester), isNull);
    await enterRifleField(tester, 'rifle-twist-rate', '1,5');
    expect(_updateAction(tester), isNull);
    await enterRifleField(tester, 'rifle-twist-rate', '9');
    expect(_updateAction(tester), isNotNull);
    // Maximum magnification below the minimum is rejected.
    await enterRifleField(tester, 'scope-max-mag', '4');
    expect(find.text('Minimum büyütmeden küçük olamaz.'), findsOneWidget);
    expect(_updateAction(tester), isNull);
    await enterRifleField(tester, 'scope-max-mag', '36');
    expect(_updateAction(tester), isNotNull);
    await enterRifleField(tester, 'rifle-caliber', '50');
    expect(find.text('2–20 arasında bir değer girin.'), findsOneWidget);
    expect(_updateAction(tester), isNull);
    await enterRifleField(tester, 'rifle-caliber', '6,35');
    expect(_updateAction(tester), isNotNull);
    // A BC outside the plausible range is rejected.
    await enterRifleField(tester, 'ammo-bc', '3');
    expect(find.text('0.005–1.5 arasında bir değer girin.'), findsOneWidget);
    expect(_updateAction(tester), isNull);
  });

  testWidgets('every typed value has an ⓘ explanation; BC opens its text', (
    tester,
  ) async {
    await _pumpAndOpen(tester, _valid);
    for (final label in const [
      'Kalibre',
      'Namlu yiv yönü',
      'Yiv oranı (1:…)',
      'Tip',
      'Ağırlık',
      'BC (balistik katsayı)',
      'BC modeli',
      'Odak düzlemi',
      'Minimum büyütme',
      'Maksimum büyütme',
      'Mercek çapı',
      'Dürbün birimi',
      'Dürbün ayağı',
      'Üst kule klik sayısı',
      'Sight height',
      'Namlu çıkış hızı',
      'Sıfırlama mesafesi',
    ]) {
      expect(find.byTooltip('Bilgi: $label'), findsOneWidget, reason: label);
    }
    // Not asked any more (owner, 2026-10-09).
    expect(find.byTooltip('Bilgi: Regülatör basıncı'), findsNothing);
    expect(find.byTooltip('Bilgi: Klik değeri'), findsNothing);
    final bcInfo = find.byTooltip('Bilgi: BC (balistik katsayı)');
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
  });
}

// Owner, 2026-10-09: yard profiles and SMOA turrets; firearm texts.
void _unitsAndFirearmTests() {
  testWidgets('Mesafe birimi Yard converts the zero and is saved', (
    tester,
  ) async {
    final store = await _pumpAndOpen(tester, _valid);
    await enterRifleField(tester, 'ammo-bc', '0,08');
    await chooseInSelect(tester, 'ammo-bc-model', 'G1');
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
    // 25 m = 27.3 yd; the field label says yd.
    expect(zero(), '27.3');
    expect(
      find.descendant(
        of: find.byKey(const Key('profile-zero')),
        matching: find.text('yd'),
      ),
      findsOneWidget,
    );
    // SMOA is offered as a turret unit.
    await chooseInSelect(
      tester,
      'profile-angular-unit-${_valid.angularUnit.name}',
      'SMOA',
    );
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
    final caliber = find.descendant(
      of: find.byKey(const Key('rifle-caliber')),
      matching: find.byType(TextField),
    );
    expect(
      tester.widget<TextField>(caliber).decoration!.hintText,
      '5,5 / 6,35 / 7,62',
    );
    await tester.tap(find.text('PCP Tüfek'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ateşli Tüfek').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(caliber).decoration!.hintText,
      '5,56 / 7,62 / 8,59',
    );
    // No pellet/slug choice for a firearm; the note says it is a bullet.
    expect(find.byKey(const Key('ammo-type')), findsNothing);
    expect(find.textContaining('Tip: mermi'), findsOneWidget);
    final grainInfo = find.byTooltip('Bilgi: Ağırlık');
    await tester.ensureVisible(grainInfo);
    await tester.tap(grainInfo);
    await tester.pumpAndSettle();
    expect(find.textContaining('.308 için 168 gr'), findsOneWidget);
  });
}
