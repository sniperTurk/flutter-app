// Screenshots for "Diğer kalibre sil" (owner, 2026-10-17 17:48–17:52,
// TestFlight 113): Profil Oluştur > Tüfek, Marka Heym, Model Express, the
// Kalibre list open with only the model's 5 calibers (no "Diğer kalibre");
// and an old profile saved with an off-model caliber (.308 Win on Heym
// Express) reopened, its caliber still shown. Report:
// docs/reports/diger_kalibre_sil.md.
//
// Run by .github/workflows/sim-screens.yml with
//   test=integration_test/diger_kalibre_sil_screens_test.dart
//   device=iPhone 16e (390 pt wide).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _offModelRifle = <String, dynamic>{
  'id': 'manual_rifle_sim_heym_308',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Heym',
  'model': 'Express',
  'caliberMm': 7.82,
  'twistDirection': 'right',
  'twistRateIn': 12,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_sim_heym_308',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '175 gr',
  'caliberMm': 7.82,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.475,
  'bcModel': 'g1',
};
const _old = RifleProfile(
  id: 'sim-heym-308',
  name: 'Eski Heym 308',
  rifleId: 'manual_rifle_sim_heym_308',
  ammunitionId: 'manual_ammo_sim_heym_308',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 805,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Diğer kalibre sil screenshots', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await ManualCatalogStore().upsert(_offModelRifle);
    await ManualCatalogStore().upsert(_ammo);
    await PersistentProfileStore().save(_old);

    final failures = <String>[];
    var counter = 0;

    Future<void> settle() async {
      try {
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 8),
        );
      } on FlutterError {
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }

    Future<void> wait(int seconds) async {
      await tester.runAsync(
        () => Future<void>.delayed(Duration(seconds: seconds)),
      );
      await settle();
    }

    Future<void> shot(String name) async {
      await settle();
      counter++;
      debugPrint('SIMSCREEN:${counter.toString().padLeft(2, '0')}_$name');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 25)),
      );
    }

    Future<void> step(String name, Future<void> Function() body) async {
      try {
        await body();
      } catch (error) {
        final line = error.toString().split('\n').first;
        failures.add('$name: $line');
        debugPrint('SIMSTEP_FAIL:$name: $line');
        await shot('FAIL_$name');
      }
    }

    Finder menuItem(String label) => find.descendant(
      of: find.byWidgetPredicate(
        (w) => w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
      ),
      matching: find.text(label),
    );

    Future<void> openSelect(String key) async {
      final box = find.byKey(Key(key));
      await tester.ensureVisible(box);
      await settle();
      await Scrollable.ensureVisible(tester.element(box), alignment: 0.3);
      await settle();
      await tester.tap(box);
      await settle();
    }

    Future<void> pick(String key, String label) async {
      await openSelect(key);
      final item = menuItem(label);
      if (item.evaluate().isEmpty) {
        tester
            .state<ScrollableState>(find.byType(Scrollable).last)
            .position
            .jumpTo(0);
        await settle();
      }
      for (var i = 0; i < 80 && item.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
        await settle();
      }
      await tester.ensureVisible(item.last);
      await settle();
      await tester.tap(item.last);
      await settle();
    }

    Future<void> openTab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(MenzilBottomNavigation),
          matching: find.text(label),
        ),
      );
      await settle();
    }

    void closeAll() {
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .popUntil((route) => route.isFirst);
    }

    app.main();
    await wait(3);
    final view = tester.view;
    final width = view.physicalSize.width / view.devicePixelRatio;
    debugPrint('SIMRECT:ekran:0,0,${width.toStringAsFixed(1)}');

    await step('heym_express_kalibre_listesi', () async {
      await openTab('Profil');
      await wait(1);
      await tester.tap(find.byTooltip('Yeni profil'));
      await settle();
      await pick('profile-platform', 'Ateşli Tüfek');
      await pick('rifle-brand-select', 'Heym');
      await pick('rifle-model-select', 'Express');
      await openSelect('rifle-caliber');
      final items = find.byWidgetPredicate(
        (w) => w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
      );
      debugPrint(
        'SIMTEXT:kalibre_ogeleri:${items.evaluate().length}:'
        'diger_kalibre=${find.text('Diğer kalibre').evaluate().length}',
      );
      await shot('heym_express_kalibre_listesi');
      // Close the open list on its own entry, then leave the editor.
      await tester.tap(menuItem('.375 H&H Mag').last);
      await settle();
      closeAll();
      await settle();
    });

    await step('eski_profil_308', () async {
      await openTab('Profil');
      await wait(1);
      final menus = find.byTooltip('Profil işlemleri');
      final names = find.text(_old.name);
      var index = 0;
      if (names.evaluate().isNotEmpty) {
        final y = tester.getCenter(names.last).dy;
        var best = double.infinity;
        for (var i = 0; i < menus.evaluate().length; i++) {
          final d = (tester.getCenter(menus.at(i)).dy - y).abs();
          if (d < best) {
            best = d;
            index = i;
          }
        }
      }
      await tester.ensureVisible(menus.at(index));
      await settle();
      await tester.tap(menus.at(index));
      await settle();
      await tester.tap(find.text('Düzenle').last);
      await settle();
      final box = find.byKey(const Key('rifle-caliber'));
      await tester.ensureVisible(box);
      await settle();
      await Scrollable.ensureVisible(tester.element(box), alignment: 0.3);
      await settle();
      await shot('eski_profil_308_kutu');
      await openSelect('rifle-caliber');
      await shot('eski_profil_308_liste');
      await tester.tap(menuItem('.308 Win').last);
      await settle();
      closeAll();
      await settle();
    });

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
