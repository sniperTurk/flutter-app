// Screenshots of the Profil page summary cards after "Profil özet etiket"
// (owner, 2026-10-17 06:08): no Tüfek / Dürbün / Mühimmat bilgileri
// titles, first rows "Tüfek Marka/Model", "Dürbün Marka/Model",
// "Mühimmat Marka/Model". For docs/reports/profil_ozet_etiket.md, 390 pt.
//
// Run by .github/workflows/sim-screens.yml with
//   test=integration_test/profil_ozet_etiket_screens_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_sim',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_sim',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test 175',
  'model': '',
  'caliberMm': 7.62,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.243,
  'bcModel': 'g7',
};

const _profile = RifleProfile(
  id: 'sim-308',
  name: 'Ateşli 308',
  rifleId: 'manual_rifle_sim',
  ammunitionId: 'manual_ammo_sim',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 805,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Profil özet etiket screenshots', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await ManualCatalogStore().upsert(_rifle);
    await ManualCatalogStore().upsert(_ammo);
    await PersistentProfileStore().save(_profile);
    await PersistentActiveProfileStore().setActiveProfileId(_profile.id);

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
        () => Future<void>.delayed(const Duration(seconds: 10)),
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

    app.main();
    await wait(3);

    // Only the pixel ratio changes (as in duzeltmeler_16_10_screens_test):
    // set twice, the first change is not always drawn.
    final physical = tester.view.physicalSize;
    for (final w in const [320.0, 390.0]) {
      tester.view.devicePixelRatio = physical.width / w;
      await wait(2);
    }

    await step('profil_390', () async {
      await tester.tap(
        find.descendant(
          of: find.byType(MenzilBottomNavigation),
          matching: find.text('Profil'),
        ),
      );
      await settle();
      for (final title in const [
        'Tüfek bilgileri',
        'Dürbün bilgileri',
        'Mühimmat bilgileri',
      ]) {
        expect(find.text(title), findsNothing, reason: title);
      }
      final rifle = find.byKey(const Key('profile-summary-rifle'));
      await Scrollable.ensureVisible(tester.element(rifle));
      await shot('profil_390_tufek');
      final scope = find.byKey(const Key('profile-summary-scope'));
      await Scrollable.ensureVisible(tester.element(scope));
      await shot('profil_390_durbun');
      final ammo = find.byKey(const Key('profile-summary-ammo'));
      await Scrollable.ensureVisible(tester.element(ammo), alignment: 1);
      await shot('profil_390_muhimmat');
      for (final label in const [
        'Tüfek Marka/Model',
        'Dürbün Marka/Model',
        'Mühimmat Marka/Model',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    debugPrint('SIMSCREEN_DONE failures=${failures.length}');
    for (final failure in failures) {
      debugPrint('SIMSTEP_SUMMARY:$failure');
    }
    expect(failures, isEmpty);
  });
}
