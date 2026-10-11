// Profil lists (owner, 2026-10-11): Tüfek Marka | Model | Kalibre and
// Mühimmat Marka | Model come from manufacturer-sourced lists.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/cartridges.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/data/rifle_library.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/rifle_form.dart';

Future<void> _openNew(WidgetTester tester, {bool firearm = false}) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
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
  if (firearm) {
    await tester.ensureVisible(find.text('PCP Tüfek'));
    await tester.tap(find.text('PCP Tüfek'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ateşli Tüfek').last);
    await tester.pumpAndSettle();
  }
}

String _text(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

Finder _in(String key, Finder f) =>
    find.descendant(of: find.byKey(Key(key)), matching: f);

void main() {
  test('the lists are manufacturer-sourced and consistent', () {
    expect(RifleLibrary.all.length, greaterThan(800));
    for (final r in RifleLibrary.all) {
      expect(r.sourceUrl, startsWith('https://'), reason: r.model);
      expect(r.brand.trim(), isNotEmpty);
      expect(r.model.trim(), isNotEmpty, reason: r.brand);
      if (r.platform == WeaponPlatform.firearm) {
        // Every firearm caliber is a Kalibre list name with its diameter.
        expect(
          Cartridges.diameterOf(r.cartridge),
          r.diameterMm,
          reason: r.model,
        );
      } else {
        expect(Cartridges.pcp.any((e) => e.$2 == r.cartridge), isTrue);
      }
    }
    expect(FactoryAmmoLibrary.all.length, greaterThan(600));
    for (final a in FactoryAmmoLibrary.all) {
      expect(Cartridges.diameterOf(a.cartridge), a.diameterMm, reason: a.name);
      expect(a.muzzleVelocityFps, inInclusiveRange(600, 4500), reason: a.name);
      expect(a.grain, inInclusiveRange(10, 900), reason: a.name);
      expect(a.bc == null, a.model == null, reason: a.name);
      if (a.bc != null) {
        expect(a.bc, inInclusiveRange(0.05, 1.2), reason: a.name);
      }
    }
    // MKE velocities measured at 23.7 m are brought back to the muzzle.
    final m80 = FactoryAmmoLibrary.all.firstWhere(
      (a) => a.brand == 'MKE' && a.name.contains('M80'),
    );
    expect(m80.muzzleVelocityFps, inInclusiveRange(2760, 2840));
    expect(m80.note, contains('23,7 m'));
  });

  testWidgets('PCP: Marka and Model on their own rows, Kalibre below', (
    tester,
  ) async {
    await _openNew(tester);
    final brand = tester.getRect(find.byKey(const Key('rifle-brand-select')));
    final model = tester.getRect(find.byKey(const Key('rifle-model-select')));
    // Each on its own full row (owner, 2026-10-11).
    expect(model.top, greaterThanOrEqualTo(brand.bottom));
    expect((brand.width - model.width).abs(), lessThan(1));
    final caliber = tester.getRect(find.byKey(const Key('rifle-caliber')));
    expect(caliber.top, greaterThanOrEqualTo(model.bottom));
    // Tür | Üretim on one row.
    final tur = tester.getRect(find.byKey(const Key('profile-platform')));
    final origin = tester.getRect(find.byKey(const Key('rifle-origin')));
    expect((tur.top - origin.top).abs(), lessThan(1));

    await chooseInSelect(tester, 'rifle-brand-select', 'Reximex');
    await chooseInSelect(tester, 'rifle-model-select', 'Apex');
    await chooseInSelect(tester, 'rifle-caliber', '5.50 mm (.22)');
    expect(_in('rifle-caliber', find.text('5.50 mm (.22)')), findsOneWidget);
    // Not a typed rifle.
    expect(find.byKey(const Key('rifle-brand')), findsNothing);
  });

  testWidgets('firearm: a model with two barrels lists both; twist fills', (
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
    expect(_text(tester, 'rifle-twist-rate'), '11');
  });

  testWidgets('"Listede yok" types Marka and Model; Kalibre has no typing', (
    tester,
  ) async {
    await _openNew(tester, firearm: true);
    await chooseInSelect(tester, 'rifle-brand-select', 'Listede yok');
    expect(find.byKey(const Key('rifle-brand')), findsOneWidget);
    expect(find.byKey(const Key('rifle-model')), findsOneWidget);
    // The last item of the long list.
    await tester.ensureVisible(find.byKey(const Key('rifle-caliber')));
    await tester.tap(find.byKey(const Key('rifle-caliber')));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Fişeğim listede yok'),
      find.byType(Scrollable).last,
      const Offset(0, -400),
    );
    await tester.tap(find.text('Fişeğim listede yok').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rifle-bullet-diameter')), findsOneWidget);
    await chooseInSelect(tester, 'rifle-bullet-diameter', '.308 in · 7,82 mm');
    // Back to the lists.
    await tester.ensureVisible(find.byKey(const Key('rifle-back-to-list')));
    await tester.tap(find.byKey(const Key('rifle-back-to-list')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rifle-brand-select')), findsOneWidget);
  });

  testWidgets('Fabrika fişeği fills weight, BC and the factory velocity', (
    tester,
  ) async {
    await _openNew(tester, firearm: true);
    await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
    expect(_in('ammo-source', find.text('Fabrika fişeği')), findsOneWidget);
    await chooseInSelect(tester, 'ammo-brand-select', 'Hornady');
    await chooseInSelect(
      tester,
      'ammo-model-select',
      'ELD Match 168 gr ELD Match',
    );
    expect(_text(tester, 'ammo-grain'), '168');
    expect(_text(tester, 'ammo-bc'), '0.263');
    expect(_text(tester, 'profile-velocity-fps'), '2700');
    expect(_in('ammo-bc-model', find.text('G7')), findsOneWidget);
    // Ağırlık | BC and BC modeli | Namlu çıkış hızı are rows of two.
    final g = tester.getRect(find.byKey(const Key('ammo-grain')));
    final bc = tester.getRect(find.byKey(const Key('ammo-bc')));
    expect((g.top - bc.top).abs(), lessThan(1));
    final m = tester.getRect(find.byKey(const Key('ammo-bc-model')));
    final v = tester.getRect(find.byKey(const Key('profile-velocity-fps')));
    expect((m.top - v.top).abs(), lessThan(1));
    // Another caliber empties the listed ammunition.
    await chooseInSelect(tester, 'rifle-caliber', '6.5 Creedmoor');
    expect(_text(tester, 'ammo-grain'), '');
  });

  testWidgets('El dolumu lists the bullet library; velocity stays typed', (
    tester,
  ) async {
    await _openNew(tester, firearm: true);
    await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
    await enterRifleField(tester, 'profile-velocity-fps', '2650');
    await chooseInSelect(tester, 'ammo-source', 'El dolumu');
    await chooseInSelect(tester, 'ammo-brand-select', 'Hornady');
    await tester.tap(find.byKey(const Key('ammo-model-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('168 gr ELD Match').last);
    await tester.pumpAndSettle();
    expect(_text(tester, 'ammo-grain'), '168');
    expect(_text(tester, 'profile-velocity-fps'), '2650');
  });
  testWidgets('Üretim Yerli lists only rifles made in Türkiye', (tester) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'rifle-origin', 'Yerli');
    await tester.tap(find.byKey(const Key('rifle-brand-select')));
    await tester.pumpAndSettle();
    expect(find.text('Hatsan'), findsWidgets);
    expect(find.text('Daystate'), findsNothing);
    await tester.tap(find.text('Hatsan').last);
    await tester.pumpAndSettle();
    // İthal drops the domestic brand.
    await chooseInSelect(tester, 'rifle-origin', 'İthal');
    expect(
      _in('rifle-brand-select', find.text('Hatsan')),
      findsNothing,
    );
  });

  testWidgets('Dürbün: a model lists only its own reticles', (tester) async {
    await _openNew(tester);
    await chooseInSelect(tester, 'scope-brand-select', 'Athlon');
    await chooseInSelect(
      tester,
      'scope-model-select',
      'Talos HMR 4-16x56 SFP IR MOA',
    );
    await tester.ensureVisible(find.byKey(const Key('scope-reticle')));
    await tester.tap(find.byKey(const Key('scope-reticle')));
    await tester.pumpAndSettle();
    expect(find.text('BDC600'), findsWidgets);
    expect(find.text('AHMC'), findsWidgets);
    expect(find.text('Center-X'), findsNothing);
    expect(find.text('MIL çizgili'), findsNothing);
    await tester.tap(find.text('AHMC').last);
    await tester.pumpAndSettle();
    expect(_text(tester, 'scope-max-mag'), '16');
    expect(_text(tester, 'scope-objective'), '56');
  });

  testWidgets('PCP mühimmat: Marka | Tip, Model on its own row', (
    tester,
  ) async {
    await _openNew(tester);
    final brand = tester.getRect(find.byKey(const Key('ammo-brand-select')));
    final type = tester.getRect(find.byKey(const Key('ammo-type')));
    expect((brand.top - type.top).abs(), lessThan(1));
    expect(brand.right, lessThan(type.left));
    final model = tester.getRect(find.byKey(const Key('ammo-model-select')));
    expect(model.top, greaterThanOrEqualTo(brand.bottom));
  });
}
